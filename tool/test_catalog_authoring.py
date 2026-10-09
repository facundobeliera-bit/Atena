"""Catalog authoring candidate, exclusively in a fresh disposable LOCAL DB."""
import argparse,concurrent.futures,json,pathlib,subprocess,sys,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
A,B,C,D=[f'{i}'*8+'-'+f'{i}'*4+'-4'+f'{i}'*3+'-8'+f'{i}'*3+'-'+f'{i}'*12 for i in range(1,5)]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);args=p.parse_args()
 r=subprocess.run([sys.executable,str(ROOT/'tool/test_shared_documents.py'),'--psql',args.psql,'--port',str(args.port)],capture_output=True,text=True,encoding='utf-8',timeout=360)
 assert r.returncode==0,r.stdout+r.stderr
 db=r.stdout.splitlines()[0].split()[1];assert db.startswith('atena_disposable_');print('LOCAL_DB '+db,flush=True)
 cmd=[args.psql,'-X','-qAt','-h','127.0.0.1','-p',str(args.port),'-U','atena_test','-d',db,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];checks=[]
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,text=True,encoding='utf-8',capture_output=True,timeout=30)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 def auth(q,who=A):return f"set role authenticated;set request.jwt.claim.sub='{who}';"+q
 def check(n,ok=True):assert ok,n;checks.append(n);print('PASS '+n,flush=True)
 def lit(d):return "'"+json.dumps(d,ensure_ascii=False).replace("'","''")+"'::jsonb"
 sql((ROOT/'supabase/candidates/20261009000000_catalog_authoring.sql').read_text(encoding='utf-8'));check('migration applies')
 sql("insert into public.atena_pilot_areas(institution_id,id,display_name) values('emission-a','authoring','TEST'); insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities) values('emission-a','authoring','operator-a',array['catalog.publish','requests.read','requests.decide']);")
 context=json.loads(sql(auth('select public.atena_authenticated_context();')));check('assigned area discoverable before namespace exists',any(c['area_id']=='authoring' for c in context['institutional_contexts']))
 def workspace(who=A):return json.loads(sql(auth("select public.atena_catalog_workspace('emission-a','authoring');",who)))
 w=workspace();check('new workspace private empty draft',w['revision']==0 and w['publication_state']=='never_published')
 doc=w['document'];gid='atena_'+'9'*64
 doc['institution'].update(country='Argentina',province='TEST',city='TEST')
 doc['groups']=[dict(id=gid,kind='curricular',name='Grupo TEST',activity_label='Actividad TEST',schedule='Lunes 10:00-11:00',capacity=2,occupied=0,available=2,availability='available',status='disponible',formal_type='escolar',price='',requirements='TEST',description='TEST',ages='Adultos')]
 def edit(action='save',who=A,op=None,document=None,revision=None,version=None,err=None):
  return sql(auth(f"select public.atena_catalog_edit('emission-a','authoring','{op or uuid.uuid4()}',{w['revision'] if revision is None else revision},{w['version'] if version is None else version},'{action}',{lit(document or doc)});",who),err)
 op=str(uuid.uuid4());old=w.copy();w=json.loads(edit(op=op));check('draft saved',w['revision']==1)
 check('same operation retry',json.loads(edit(op=op,revision=old['revision'],version=old['version']))==w)
 check('draft hidden from public',gid not in sql("set role anon;select coalesce(json_agg(p),'[]') from public.atena_catalog_read() p;"))
 sql("set role authenticated;select * from atena_private.catalog_drafts;",'42501');check('draft table private')
 edit(who=B,err='42501');check('foreign operator denied')
 edit(who=C,err='42501');check('student cannot author')
 sql("set role anon;select public.atena_catalog_workspace('emission-a','authoring');",'42501');check('anonymous workspace denied')
 doc['groups'][0]['description']='Edited TEST';w=json.loads(edit());check('draft edited',w['document']['groups'][0]['description']=='Edited TEST')
 edit(revision=0,err='PT409');check('stale draft rejected')
 saved_schedule=doc['groups'][0]['schedule'];doc['groups'][0]['schedule']='';edit('publish',err='22023');doc['groups'][0]['schedule']=saved_schedule;check('incomplete public offer denied')
 w=json.loads(edit('publish'));check('published',w['publication_state']=='published')
 check('public reader sees publication',gid in sql("set role anon;select json_agg(p) from public.atena_catalog_read() p;"))
 request=json.loads(sql(auth(f"select row_to_json(r) from public.atena_request_create('student-c','{gid}','{uuid.uuid4()}') r;",C)));check('student requests new offer',request['state']=='pending')
 confirmed=json.loads(sql(auth(f"select row_to_json(r) from public.atena_request_decide('{request['id']}','confirmed') r;")));check('authorized confirmation',confirmed['state']=='confirmed')
 pub=json.loads(sql("set role anon;select json_agg(p) from public.atena_catalog_read() p;"));group=next(g for p in pub for g in p['document']['groups'] if g['id']==gid);check('shared availability decreases',group['available']==1 and group['occupied']==1)
 doc['groups'][0].update(capacity=0,available=0,availability='full');edit('publish',err='PT409');check('cannot lower capacity below confirmed')
 doc['groups'][0].update(capacity=2,available=2,availability='available');w=json.loads(edit('publish'));check('client zero occupancy cannot erase confirmed',w['document']['groups'][0]['occupied']==1)
 w=json.loads(edit('withdraw'));check('withdrawal preserved',w['publication_state']=='withdrawn')
 check('withdrawn absent anonymously',gid not in sql("set role anon;select coalesce(json_agg(p),'[]') from public.atena_catalog_read() p;"))
 check('historical confirmation retained',sql(f"select state from public.atena_requests where id='{request['id']}';")=='confirmed')
 doc['groups'][0]['description']='draft after withdrawal';w=json.loads(edit());check('saving draft never republishes',w['publication_state']=='withdrawn')
 sql(auth(f"select public.atena_request_create('student-d','{gid}','{uuid.uuid4()}');",D),'42501');check('withdrawn rejects new request')
 # Existing accepted key still returns the original request, independently of catalog visibility.
 retry=json.loads(sql(auth(f"select row_to_json(r) from public.atena_request_create('student-c','{gid}','{request['operation_id']}') r;",C)));check('withdrawn accepted retry remains recoverable',retry['id']==request['id'])
 rev=w['revision'];ver=w['version'];ops=[str(uuid.uuid4()),str(uuid.uuid4())]
 def race(op):return subprocess.run(cmd,input=auth(f"select public.atena_catalog_edit('emission-a','authoring','{op}',{rev},{ver},'save',{lit(doc)});"),capture_output=True,text=True,encoding='utf-8',timeout=30)
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:out=list(pool.map(race,ops))
 check('concurrent edit exactly one winner',sum(r.returncode==0 for r in out)==1 and any('PT409' in r.stderr for r in out))
 sql("update public.atena_pilot_assignments set active=false where institution_id='emission-a' and area_id='authoring';")
 edit(op=op,revision=old['revision'],version=old['version'],err='42501');check('revoked operator cannot recover edit receipt')
 legacy=json.loads(json.dumps(doc));legacy['schema_version']=2
 for g in legacy['groups']:
  for key in ['formal_type','price','requirements','description','ages']:g.pop(key)
 sql("update public.atena_catalog_publications set document="+lit(legacy)+" where area_id='"+w['document']['area']['id']+"';delete from atena_private.catalog_drafts where institution_id='emission-a' and area_id='authoring';update public.atena_pilot_assignments set active=true where institution_id='emission-a' and area_id='authoring';")
 compatible=workspace();check('legacy projection editable without rewrite',compatible['document']['schema_version']==3 and compatible['document']['groups'][0]['formal_type']=='escolar' and sql("select document->>'schema_version' from public.atena_catalog_publications where area_id='"+w['document']['area']['id']+"';")=='2')
 check('commercial remains OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print('SUMMARY '+str(len(checks))+' AUTHORING PASS + 175 BASE PASS',flush=True)
if __name__=='__main__':main()
