"""LOCAL disposable public profile acceptance; never connects to Supabase.
Claims/Auth rows are local fixtures, not a real JWT campaign.
"""
import argparse, concurrent.futures, json, pathlib, subprocess, threading, uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55441);p.add_argument('--base-db',required=True);a=p.parse_args()
 assert a.base_db.startswith('atena_disposable_') and all(c.isalnum() or c=='_' for c in a.base_db)
 db='atena_disposable_profile_'+uuid.uuid4().hex[:12]
 cmd=[a.psql,'-X','-qAt','-h','127.0.0.1','-p',str(a.port),'-U','atena_test','-d','postgres','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose']
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,capture_output=True,text=True,encoding='utf-8',timeout=45)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 sql(f'create database {db} template {a.base_db};');cmd[cmd.index('-d')+1]=db;print('LOCAL_DB '+db,flush=True)
 checks=[]
 def check(n,ok=True):assert ok,n;checks.append(n);print('PASS '+n,flush=True)
 def lit(d):return "'"+json.dumps(d).replace("'","''")+"'::jsonb"
 tables=json.loads(sql("select json_agg(quote_ident(schemaname)||'.'||quote_ident(tablename)) from pg_tables where schemaname in ('public','atena_private','auth');"))
 def digest(t):return sql(f"select md5(coalesce(string_agg(h,',' order by h),'')) from (select md5(to_jsonb(r)::text) h from {t} r) s;")
 before={t:digest(t) for t in tables}
 sql((ROOT/'supabase/candidates/20261016020000_institution_public_profile.sql').read_text(encoding='utf-8-sig'))
 check('migration preserves every existing row',all(digest(t)==h for t,h in before.items()))
 users={n:str(uuid.uuid4()) for n in ['owner','reviewer','stranger','operator','unverified']};sessions={n:str(uuid.uuid4()) for n in users}
 for n,u in users.items():sql(f"insert into auth.users(id,email,email_confirmed_at) values('{u}','profile-{n}@example.invalid',"+('null' if n=='unverified' else 'now()')+f");insert into auth.sessions(id,user_id) values('{sessions[n]}','{u}');")
 def auth(q,w='owner'):return f"set role authenticated;set request.jwt.claim.sub='{users[w]}';set request.jwt.claims='{json.dumps({'sub':users[w],'session_id':sessions[w]})}';"+q
 def onboard(action,data,w='owner'):return json.loads(sql(auth(f"select public.atena_onboarding_command('{action}',{lit(data)});",w)))
 sql(f"set role service_role;select public.atena_onboarding_reviewer('{users['reviewer']}',true);")
 app=onboard('apply',dict(operation_id=str(uuid.uuid4()),name='TEST Profile Institution',reference='TEST Profile registration'))
 inst=onboard('approve',dict(application_id=app['application_id'],review_reference='TEST independently verified',representation_checked=True),'reviewer')['institution_id']
 area=json.loads(sql(auth('select public.atena_onboarding_state();')))['institutions'][0]['areas'][0]['id']
 invitation=onboard('invite',dict(institution_id=inst,area_id=area,email='profile-operator@example.invalid',capabilities=['catalog.publish','requests.read','requests.decide']))
 onboard('accept_invitation',dict(invitation_id=invitation['invitation_id']),'operator')
 def read(w='owner',err=None):
  out=sql(auth(f"select public.atena_institution_profile('{inst}');",w),err);return None if err else json.loads(out)
 def save(doc,rev=0,op=None,w='owner',err=None):
  out=sql(auth(f"select public.atena_institution_profile_save('{inst}','{op or uuid.uuid4()}',{rev},{lit(doc)});",w),err);return None if err else json.loads(out)
 check('owner starts with independent empty public profile',read()['revision']==0)
 doc=read()['document'];doc.update(public_name='TEST Public Name',description='TEST public description',country='Argentina',province='TEST Province',city='TEST City',address='TEST address',phone='TEST phone',email='test@example.invalid',opening_hours='TEST lunes 9 a 12')
 for actor in ['operator','reviewer','stranger','unverified']:
  read(actor,'42501');save(doc,w=actor,err='42501');check(actor+' cannot read or edit owner profile')
 sql(f"set role anon;select public.atena_institution_profile('{inst}');",'42501');check('anonymous cannot inspect owner workspace')
 for field in ['owner_auth_user_id','institution_id','legal_name','role','birth_date','document_number']:
  save({**doc,field:'forbidden'},err='22023');check('rejects privileged '+field)
 for d in [{**doc,'email':'invalid'}, {**doc,'public_name':''}, {**doc,'phone':None}, {**doc,'description':'x'*2001}, {k:v for k,v in doc.items() if k!='phone'}]:save(d,err='22023')
 check('malformed missing and oversized fields rejected')
 fixed={t:digest(t) for t in ['auth.users','auth.sessions','public.atena_pilot_institutions','public.atena_pilot_operators','public.atena_pilot_identity_links','public.atena_pilot_assignments','atena_private.applicant_access']}
 op=str(uuid.uuid4());result=save(doc,op=op)
 check('owner save acknowledged and persisted',result['revision']==1 and read()['document']==doc)
 check('same retry idempotent',save(doc,op=op)==result)
 save({**doc,'phone':'changed'},op=op,err='PT409');check('retry key cannot change content')
 save(doc,err='PT409');check('stale revision rejected')
 check('no Auth ownership or family changes',all(digest(t)==h for t,h in fixed.items()))
 for table in ['institution_public_profiles','institution_profile_events']:
  check(table+' RLS enabled',sql(f"select relrowsecurity from pg_class where oid='atena_private.{table}'::regclass;")=='t')
  sql(auth(f'select * from atena_private.{table};'),'42501');sql(auth(f'delete from atena_private.{table};'),'42501');check(table+' unavailable directly to clients')
 workspace=json.loads(sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');")));catalog=workspace['document'];gid='atena_'+uuid.uuid4().hex*2
 catalog['institution'].update(country='Argentina',province='TEST',city='TEST')
 catalog['groups']=[dict(id=gid,kind='curricular',name='TEST Group',activity_label='TEST',schedule='Lunes 10:00-11:00',capacity=2,occupied=0,available=2,availability='available',status='disponible',formal_type='escolar',price='',requirements='TEST',description='TEST',ages='TEST')]
 publicid=catalog['institution']['id']
 def visible():return json.loads(sql(f"set role anon;select coalesce(json_agg(p),'[]') from public.atena_catalog_read() p where institution_id='{publicid}';"))
 check('profile alone does not publish institution',visible()==[])
 sql(auth(f"select public.atena_catalog_edit('{inst}','{area}','{uuid.uuid4()}',0,0,'save',{lit(catalog)});"));check('private draft does not publish contact',visible()==[])
 sql(auth(f"select public.atena_catalog_edit('{inst}','{area}','{uuid.uuid4()}',1,0,'publish',{lit(catalog)});"))
 publication_hash=digest('public.atena_catalog_publications')
 public=visible()[0]['document']['institution'];check('public read exposes only public presentation',public['name']==doc['public_name'] and public['email']==doc['email'] and public['opening_hours']==doc['opening_hours'] and 'actor' not in public and 'owner_auth_user_id' not in public)
 check('shared availability unchanged',visible()[0]['document']['groups'][0]['available']==2)
 doc2={**doc,'phone':'TEST new phone'};save(doc2,1);check('update visible across subsequent independent read',visible()[0]['document']['institution']['phone']=='TEST new phone')
 check('published historical document not overwritten',digest('public.atena_catalog_publications')==publication_hash)
 check('profile audit preserves old and new values',sql(f"select count(*) from atena_private.institution_profile_events where institution_id='{inst}' and previous_document->>'phone'='TEST phone' and document->>'phone'='TEST new phone';")=='1')
 barrier=threading.Barrier(2)
 def race(n):
  barrier.wait();return subprocess.run(cmd,input=auth(f"select public.atena_institution_profile_save('{inst}','{uuid.uuid4()}',2,{lit({**doc2,'phone':'TEST race '+str(n)})});"),capture_output=True,text=True,encoding='utf-8',timeout=40)
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(race,[1,2]))
 check('concurrent writers do not overwrite silently',sum(r.returncode==0 for r in results)==1 and all(r.returncode==0 or 'PT409' in r.stderr for r in results) and read()['revision']==3)
 sql(auth(f"select public.atena_catalog_edit('{inst}','{area}','{uuid.uuid4()}',2,1,'withdraw',{lit(catalog)});"));check('withdraw hides profile with its offers',visible()==[])
 sql(f"update public.atena_pilot_identity_links set active=false,revoked_at=now() where institution_id='{inst}' and auth_user_id='{users['owner']}';")
 save(doc,3,err='42501');read(err='42501');check('revoked owner link immediately denies access')
 sql(f"delete from auth.sessions where id='{sessions['owner']}';");read(err='42501');check('revoked session denied')
 check('commercial enforcement remains off',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print(f'SUMMARY {len(checks)} INSTITUTION PROFILE PASS',flush=True)
if __name__=='__main__':main()
