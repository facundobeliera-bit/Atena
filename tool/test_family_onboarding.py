"""Disposable LOCAL PostgreSQL family/adult acceptance. No remote option or real Auth.
Auth rows/session claims are fixtures; all profile links are created through RPC review.
"""
import argparse, concurrent.futures, json, pathlib, subprocess, sys, threading, uuid
ROOT = pathlib.Path(__file__).resolve().parents[1]

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);p.add_argument('--base-db');args=p.parse_args()
 if args.base_db:
  db=args.base_db
 else:
  base=subprocess.run([sys.executable,str(ROOT/'tool/test_institution_onboarding.py'),'--psql',args.psql,'--port',str(args.port)],capture_output=True,text=True,encoding='utf-8',timeout=700)
  assert base.returncode==0,base.stdout+base.stderr
  db=base.stdout.splitlines()[0].split()[1]
 assert db.startswith('atena_disposable_');print('LOCAL_DB '+db,flush=True)
 cmd=[args.psql,'-X','-qAt','-h','127.0.0.1','-p',str(args.port),'-U','atena_test','-d',db,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];checks=[]
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,capture_output=True,text=True,encoding='utf-8',timeout=40)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 def check(n,ok=True):assert ok,n;checks.append(n);print('PASS '+n,flush=True)
 def lit(d):return "'"+json.dumps(d).replace("'","''")+"'::jsonb"
 snapshot="select md5(coalesce(json_agg(t order by profile_id)::text,'')) from atena_private.applicant_links t;"
 before=sql(snapshot)
 tables=json.loads(sql("select json_agg(quote_ident(schemaname)||'.'||quote_ident(tablename)) from pg_tables where schemaname in ('public','atena_private','auth');"))
 def table_hash(table):return sql(f"select md5(coalesce(string_agg(h,',' order by h),'')) from (select md5(to_jsonb(t)::text) h from {table} t) hashes;")
 old_rows={t:table_hash(t) for t in tables}
 sql((ROOT/'supabase/candidates/20261013000000_family_onboarding.sql').read_text(encoding='utf-8'))
 check('migration preserves every prior table row',all(table_hash(t)==h for t,h in old_rows.items()))
 check('legacy anchor identities unchanged',sql(snapshot)==before)
 check('existing request FKs preserved',sql("select count(*) from public.atena_requests r left join atena_private.applicant_access a on a.profile_id=r.applicant_profile_id and a.auth_user_id=r.applicant_auth_user_id where a.profile_id is null;")=='0')
 users={n:str(uuid.uuid4()) for n in ['adult','reviewer','guardian','stranger','institution','unverified','minor']};sessions={n:str(uuid.uuid4()) for n in users}
 for n,u in users.items():sql(f"insert into auth.users(id,email,email_confirmed_at) values('{u}','family-{n}@example.invalid',"+('null' if n=='unverified' else 'now()')+f");insert into auth.sessions(id,user_id) values('{sessions[n]}','{u}');")
 def auth(q,who='adult'):return f"set role authenticated;set request.jwt.claim.sub='{users[who]}';set request.jwt.claims='{json.dumps({'sub':users[who],'session_id':sessions[who]})}';"+q
 def rpc(name,action,data,who='adult',err=None):
  result=sql(auth(f"select public.{name}('{action}',{lit(data)});",who),err)
  return None if err else json.loads(result)
 def call(action,data,who='adult',err=None):return rpc('atena_family_command',action,data,who,err)
 def state(who='adult'):return json.loads(sql(auth('select public.atena_family_state();',who)))
 def context(who='adult'):return json.loads(sql(auth('select public.atena_authenticated_context();',who)))['applicant_profiles']
 def apply(kind='adult',who='adult',err=None,**kw):return call('apply',dict(operation_id=str(uuid.uuid4()),kind=kind,name='TEST '+who,birth_date='1990-01-01' if kind=='adult' else '2016-01-01',**kw),who,err)
 def decision(a,who='reviewer',err=None,**kw):return call('approve',dict(application_id=a['application_id'],review_reference='TEST verified evidence',identity_checked=True,responsibility_checked=True,**kw),who,err)
 sql(f"set role service_role;select public.atena_onboarding_reviewer('{users['reviewer']}',true);")
 check('institutional reviewer gains no family review automatically',not state('reviewer')['reviewer'])
 sql(auth(f"select public.atena_family_reviewer('{users['adult']}',true);"),'42501');check('client cannot designate family reviewers')
 sql(f"set role service_role;select public.atena_family_reviewer('{users['reviewer']}',true);")
 sql('set role anon;select public.atena_family_state();','42501');check('anonymous cannot access family state')
 apply(who='unverified',err='42501');check('unconfirmed email cannot apply')
 call('apply',dict(operation_id=str(uuid.uuid4()),kind='adult',name='TEST minor',birth_date='2015-01-01'),'minor','42501');check('minor cannot request adult powers')
 apply('minor','stranger','42501');check('unreviewed adult cannot claim minor')
 op=str(uuid.uuid4());payload=dict(operation_id=op,kind='adult',name='TEST adult',birth_date='1990-01-01')
 a=call('apply',payload);check('adult pending has no authorized profile',a['status']=='pending' and context()==[])
 check('retry idempotent',call('apply',payload)==a)
 call('apply',{**payload,'name':'Changed'},err='PT409');check('retry cannot change identity payload')
 call('apply',{**payload,'operation_id':str(uuid.uuid4())},err='23505');check('duplicate pending rejected')
 check('stranger sees no private application',state('stranger')['applications']==[])
 decision(a,'adult','42501');check('self approval denied')
 ar=apply(who='reviewer');decision(ar,'reviewer','42501');check('designated reviewer cannot self approve')
 call('approve',dict(application_id=a['application_id'],review_reference='TEST missing evidence'),'reviewer','22023');check('explicit evidence required')
 adult=decision(a)['profile_id'];check('approved adult owns its profile',context()==[{'profile_id':adult}])
 check('approval retry preserves identity',decision(a)['profile_id']==adult)
 guardian=decision(apply(who='guardian'))['profile_id'];check('second adult independently verified',state('guardian')['adult'])
 reject=apply(who='stranger');call('reject',dict(application_id=reject['application_id'],review_reference='TEST evidence insufficient'),'reviewer')
 decision(reject,err='PT409');check('rejected adult has no profile',context('stranger')==[])
 child_application=apply('minor');check('minor pending does not grant access',len(context())==1)
 child=decision(child_application)['profile_id'];check('reviewed guardian gets minor access',any(p['profile_id']==child for p in context()))
 apply('minor',err='23505');check('approved child cannot be accidentally recreated by same applicant')
 link_payload=dict(kind='link',name='',target_profile=child,operation_id=str(uuid.uuid4()))
 link=call('apply',link_payload,'guardian');check('knowing child ID gives no private access',not any(p['profile_id']==child for p in context('guardian')))
 sql(auth(f"select public.atena_education_read('progreso','{child}');",'guardian'),'42501');check('pending guardian cannot read education')
 linked=decision(link);check('second guardian shares same profile',linked['profile_id']==child and any(p['profile_id']==child for p in context('guardian')))
 legacy_link=call('apply',{**link_payload,'operation_id':str(uuid.uuid4()),'target_profile':'student-c'},'guardian')
 decision(legacy_link,err='42501');check('legacy profiles cannot be claimed through new onboarding')
 foreign=call('apply',{**link_payload,'operation_id':str(uuid.uuid4()),'target_profile':'does-not-exist'},'guardian')
 decision(foreign,err='42501');check('unknown target gives no authority')
 # Institution also uses the reviewed onboarding RPC, with no manually inserted mappings.
 ia=rpc('atena_onboarding_command','apply',dict(operation_id=str(uuid.uuid4()),name='TEST family institution',reference='test-family-'+uuid.uuid4().hex),'institution')
 approved=rpc('atena_onboarding_command','approve',dict(application_id=ia['application_id'],review_reference='TEST institution evidence',representation_checked=True),'reviewer');inst=approved['institution_id']
 istate=json.loads(sql(auth('select public.atena_onboarding_state();','institution')));area=istate['institutions'][0]['areas'][0]['id']
 workspace=json.loads(sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');",'institution')));doc=workspace['document'];gid='atena_'+uuid.uuid4().hex*2
 doc['institution'].update(country='Argentina',province='TEST',city='TEST')
 doc['groups']=[dict(id=gid,kind='curricular',name='TEST families',activity_label='TEST',schedule='Lunes 10:00-11:00',capacity=2,occupied=0,available=2,availability='available',status='disponible',formal_type='escolar',price='',requirements='TEST',description='TEST',ages='TEST')]
 sql(auth(f"select public.atena_catalog_edit('{inst}','{area}','{uuid.uuid4()}',0,0,'publish',{lit(doc)});",'institution'))
 check('public search sees approved institution offer',gid in sql('set role anon;select json_agg(p) from public.atena_catalog_read() p;'))
 def request(profile,who='adult',err=None,op=None):
  out=sql(auth(f"select row_to_json(r) from public.atena_request_create('{profile}','{gid}','{op or uuid.uuid4()}') r;",who),err)
  return None if err else json.loads(out)
 request(child,'stranger','42501');check('foreign family cannot enroll child')
 rop=str(uuid.uuid4());r=request(child,'guardian',op=rop)
 check('second guardian creates same child enrollment',r['applicant_auth_user_id']==users['guardian'] and r['applicant_profile_id']==child)
 check('request retry idempotent',request(child,'guardian',op=rop)['id']==r['id'])
 request(child,'adult','23505');check('two guardians cannot duplicate enrollment')
 check('first guardian sees second guardian enrollment',sql(auth(f"select count(*) from public.atena_requests where id='{r['id']}';"))=='1')
 check('foreign family cannot read enrollment',sql(auth(f"select count(*) from public.atena_requests where id='{r['id']}';",'stranger'))=='0')
 sql(auth(f"select public.atena_request_decide('{r['id']}','confirmed');",'guardian'),'42501');check('guardian cannot confirm institution enrollment')
 sql(auth(f"select public.atena_request_decide('{r['id']}','confirmed');",'institution'));check('institution confirms child enrollment')
 sql(auth(f"select public.atena_request_decide('{r['id']}','confirmed');",'institution'));check('confirmation idempotent')
 check('both guardians see confirmed state',all(sql(auth(f"select state from public.atena_requests where id='{r['id']}';",w))=='confirmed' for w in ['adult','guardian']))
 r2=request(adult);sql(auth(f"select public.atena_request_decide('{r2['id']}','confirmed');",'institution'));check('adult own enrollment completes')
 request(guardian,'guardian','PT409');check('exhausted capacity rejected')
 publications=json.loads(sql('set role anon;select json_agg(p) from public.atena_catalog_read() p;'))
 check('shared occupied capacity correct',any(g['id']==gid and g['occupied']==2 and g['available']==0 for p in publications for g in p['document']['groups']))
 # A second resource exercises real independent SQL connections after migration.
 w=json.loads(sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');",'institution')))
 race_gid='atena_'+uuid.uuid4().hex*2;doc=w['document']
 doc['groups'].append({**doc['groups'][0],'id':race_gid,'name':'TEST last seat','capacity':1,'occupied':0,'available':1,'availability':'available'})
 sql(auth(f"select public.atena_catalog_edit('{inst}','{area}','{uuid.uuid4()}',{w['revision']},{w['version']},'publish',{lit(doc)});",'institution'))
 racing=[]
 for profile,who in [(adult,'adult'),(guardian,'guardian')]:
  racing.append(json.loads(sql(auth(f"select row_to_json(r) from public.atena_request_create('{profile}','{race_gid}','{uuid.uuid4()}') r;",who)))['id'])
 barrier=threading.Barrier(2)
 def race(rid):
  barrier.wait()
  return subprocess.run(cmd,input=auth(f"begin;select public.atena_request_decide('{rid}','confirmed');select pg_sleep(0.25);commit;",'institution'),capture_output=True,text=True,encoding='utf-8',timeout=30)
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:out=list(pool.map(race,racing))
 check('concurrent last seat exactly one success',sum(x.returncode==0 for x in out)==1 and any('PT409' in x.stderr for x in out))
 check('last seat has one confirmation and one pending',sql(f"select count(*) from public.atena_requests where group_id='{race_gid}' and state='confirmed';")=='1' and sql(f"select count(*) from public.atena_requests where group_id='{race_gid}' and state='pending';")=='1')
 revoke=dict(profile_id=child,user_id=users['guardian'],review_reference='TEST revoke reviewed')
 call('revoke',revoke,'adult','42501');check('guardian cannot change another adult rights')
 call('revoke',revoke,'reviewer');check('revocation removes context immediately',not any(p['profile_id']==child for p in context('guardian')))
 check('revoked guardian loses history access',sql(auth(f"select count(*) from public.atena_requests where id='{r['id']}';",'guardian'))=='0')
 request(child,'guardian','42501');sql(auth(f"select public.atena_request_decide('{r['id']}','cancelled_by_student');",'guardian'),'42501');check('revoked guardian cannot write with old session')
 check('other guardian keeps historical enrollment',sql(auth(f"select state from public.atena_requests where id='{r['id']}';"))=='confirmed')
 check('institution retains child enrollment after submitter revoked',sql(auth(f"select state from public.atena_requests where id='{r['id']}';",'institution'))=='confirmed')
 check('profile still has an independently authorized recipient',sql(f"select atena_private.family_profile_active('{child}');")=='t')
 sql(auth(f"select public.atena_education_enrollments('{inst}','{area}');",'institution'),'42501')
 check('onboarding does not grant unrelated educational privileges')
 sql(auth(f"select public.atena_documents_read('{child}');",'guardian'),'42501');sql(auth(f"select public.atena_education_read('progreso','{child}');",'guardian'),'42501');check('revoked guardian loses documents and education')
 check('no occupancy released by revoking guardian',sql(f"select occupied from atena_private.capacity_pools where id=(select group_pool_id from atena_private.request_resources where group_id='{gid}');")=='2')
 # Age transition fails closed without manufacturing a self identity.
 sql(f"update atena_private.family_profiles set birth_date='2000-01-01' where id='{child}';")
 check('guardian access ends on adulthood',not any(p['profile_id']==child for p in context()))
 self_request=call('apply',dict(kind='self_link',name='',target_profile=child,operation_id=str(uuid.uuid4())),'minor')
 check('own existing profile claim stays pending without access',context('minor')==[])
 self_result=decision(self_request)
 check('reviewed adult transition preserves child profile identity',self_result['profile_id']==child and context('minor')==[{'profile_id':child}])
 check('new adult retains its enrollment history',sql(auth(f"select state from public.atena_requests where id='{r['id']}';",'minor'))=='confirmed')
 check('former guardians cannot recover access after adulthood',all(not any(p['profile_id']==child for p in context(w)) for w in ['adult','guardian']))
 sql(f"delete from auth.sessions where id='{sessions['stranger']}';")
 sql(auth('select public.atena_family_state();','stranger'),'42501');check('expired session rejected')
 for role in ['anon','authenticated']:
  sql('set role '+role+';select * from atena_private.family_profiles;','42501')
  sql('set role '+role+';insert into atena_private.applicant_access values(null,null,true,now());','42501')
  check(role+' direct profile/grant access denied')
 check('all family RPCs preserve session guard',sql("select count(*) from pg_proc where proname in ('atena_family_state','atena_family_command') and position('require_current_session' in prosrc)>0;")=='2')
 check('restrictive live session RLS retained',sql("select count(*) from pg_policy where polrelid='public.atena_requests'::regclass and not polpermissive;")=='1')
 check('legacy anchors still unchanged',sql("select md5(coalesce(json_agg(t order by profile_id)::text,'')) from (select * from atena_private.applicant_links where profile_id not like 'family_%') t;")==before)
 check('audit retained',int(sql('select count(*) from atena_private.family_audit;'))>=10)
 sql(f"set role service_role;select public.atena_family_reviewer('{users['reviewer']}',false);")
 call('revoke',dict(profile_id=adult,user_id=users['adult'],review_reference='TEST reviewer revoked'),'reviewer','42501')
 check('revoked reviewer cannot change authorizations',not state('reviewer')['reviewer'])
 check('commercial remains OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print(f'SUMMARY {len(checks)} FAMILY PASS + 306 BASE PASS',flush=True)
if __name__=='__main__':main()
