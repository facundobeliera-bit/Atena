"""Local-only essential operations acceptance. SQL roles/claims are fixtures, not JWT.
Clone a disposable baseline; never mutate its data and never connect remotely.
"""
import argparse, concurrent.futures, json, pathlib, subprocess, threading, uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55441);p.add_argument('--base-db',required=True);a=p.parse_args()
 assert a.base_db.startswith('atena_disposable_') and all(c.isalnum() or c=='_' for c in a.base_db)
 db='atena_disposable_essential_'+uuid.uuid4().hex[:12]
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
 for name in ['20261016000000_enrollment_withdrawal.sql','20261016010000_identity_rectification.sql']:
  sql((ROOT/'supabase/candidates'/name).read_text(encoding='utf-8'))
  check(name+' preserves all pre-existing rows',all(digest(t)==h for t,h in before.items()))
 users={n:str(uuid.uuid4()) for n in ['owner','reviewer','familyreview','adult','second','stranger','readonly','operator','unverified']};sessions={n:str(uuid.uuid4()) for n in users}
 for n,u in users.items():sql(f"insert into auth.users(id,email,email_confirmed_at) values('{u}','essential-{n}@example.invalid',"+('null' if n=='unverified' else 'now()')+f");insert into auth.sessions(id,user_id) values('{sessions[n]}','{u}');")
 def auth(q,w='owner'):return f"set role authenticated;set request.jwt.claim.sub='{users[w]}';set request.jwt.claims='{json.dumps({'sub':users[w],'session_id':sessions[w]})}';"+q
 def rpc(fn,action,data,w='owner',err=None):
  out=sql(auth(f"select public.{fn}('{action}',{lit(data)});",w),err);return None if err else json.loads(out)
 def onboarding(action,data,w='owner',err=None):return rpc('atena_onboarding_command',action,data,w,err)
 def family(action,data,w='adult',err=None):return rpc('atena_family_command',action,data,w,err)
 def correction(action,data,w='adult',err=None):return rpc('atena_identity_correction_command',action,data,w,err)
 def state(w):return json.loads(sql(auth('select public.atena_identity_correction_state();',w)))
 sql(f"set role service_role;select public.atena_onboarding_reviewer('{users['reviewer']}',true);select public.atena_family_reviewer('{users['familyreview']}',true);")
 ia=onboarding('apply',dict(operation_id=str(uuid.uuid4()),name='TEST essential institution',reference='TEST essential evidence'))
 inst=onboarding('approve',dict(application_id=ia['application_id'],review_reference='TEST authorized evidence',representation_checked=True),'reviewer')['institution_id']
 foreign=onboarding('apply',dict(operation_id=str(uuid.uuid4()),name='TEST other institution',reference='TEST foreign institution'),'stranger')
 onboarding('approve',dict(application_id=foreign['application_id'],review_reference='TEST independently verified',representation_checked=True),'reviewer')
 area=json.loads(sql(auth('select public.atena_onboarding_state();')))['institutions'][0]['areas'][0]['id']
 for w,caps in [('readonly',['requests.read']),('operator',['requests.read','requests.decide'])]:
  iv=onboarding('invite',dict(institution_id=inst,area_id=area,email='essential-'+w+'@example.invalid',capabilities=caps))
  onboarding('accept_invitation',dict(invitation_id=iv['invitation_id']),w)
 profiles={}
 for w in ['adult','second']:
  ap=family('apply',dict(operation_id=str(uuid.uuid4()),kind='adult',name='TEST '+w,birth_date='1990-01-01'),w)
  profiles[w]=family('approve',dict(application_id=ap['application_id'],review_reference='TEST family evidence',identity_checked=True,responsibility_checked=True),'familyreview')['profile_id']
 childapp=family('apply',dict(operation_id=str(uuid.uuid4()),kind='minor',name='TEST child',birth_date='2016-01-01'))
 child=family('approve',dict(application_id=childapp['application_id'],review_reference='TEST child evidence',identity_checked=True,responsibility_checked=True),'familyreview')['profile_id']
 w=json.loads(sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');")));doc=w['document'];gid='atena_'+uuid.uuid4().hex*2
 doc['institution'].update(country='Argentina',province='TEST',city='TEST')
 doc['groups']=[dict(id=gid,kind='curricular',name='TEST withdrawals',activity_label='TEST',schedule='Lunes 10:00-11:00',capacity=4,occupied=0,available=4,availability='available',status='disponible',formal_type='escolar',price='',requirements='TEST',description='TEST',ages='TEST')]
 sql(auth(f"select public.atena_catalog_edit('{inst}','{area}','{uuid.uuid4()}',0,0,'publish',{lit(doc)});"))
 def request(w='adult'):
  return json.loads(sql(auth(f"select row_to_json(r) from public.atena_request_create('{profiles[w]}','{gid}','{uuid.uuid4()}') r;",w)))['id']
 def decide(r,err=None):sql(auth(f"select public.atena_request_decide('{r}','confirmed');"),err)
 def withdraw(r,w='owner',reason='TEST approved withdrawal',err=None):
  out=sql(auth(f"select row_to_json(e) from public.atena_enrollment_withdraw('{r}','{reason}') e;",w),err);return None if err else json.loads(out)
 def occupied():return int(sql(f"select occupied from atena_private.capacity_pools where id=(select group_pool_id from atena_private.request_resources where group_id='{gid}');"))
 r=request();withdraw(r,err='PT409');check('pending request cannot use confirmed withdrawal')
 decide(r);snapshot=json.loads(sql(f"select row_to_json(r) from public.atena_requests r where id='{r}';"))
 for actor in ['adult','stranger','readonly']:
  withdraw(r,actor,err='42501');check(actor+' cannot withdraw enrollment')
 withdraw(r,reason='short',err='22023');check('auditable reason required',occupied()==1)
 event=withdraw(r,'operator');check('scoped decision operator withdraws with audit',event['confirmed_at']==snapshot['updated_at'] and event['confirmed_by_auth_user_id']==users['owner'] and event['withdrawn_by_auth_user_id']==users['operator'] and occupied()==0)
 check('same retry does not release twice',withdraw(r,'operator')==event and occupied()==0)
 withdraw(r,reason='TEST changed reason',err='PT409');check('conflicting retry rejected')
 decide(r,'PT409');check('withdrawn enrollment cannot reconfirm')
 check('confirmation actor retained',sql(f"select decided_by_auth_user_id from public.atena_requests where id='{r}';")==users['owner'])
 for actor,count in [('adult','1'),('owner','1'),('readonly','1'),('stranger','0'),('second','0')]:
  check(actor+' audit visibility',sql(auth(f"select count(*) from public.atena_enrollment_withdrawals where request_id='{r}';",actor))==count)
 for q in [f"delete from public.atena_enrollment_withdrawals where request_id='{r}';",f"update public.atena_enrollment_withdrawals set reason='TEST altered' where request_id='{r}';"]:sql(auth(q),'42501')
 check('audit cannot be edited or deleted by clients')
 r2=request();decide(r2);check('new enrollment after withdrawal possible',occupied()==1)
 sql(f"update atena_private.capacity_pools set occupied=3 where id=(select group_pool_id from atena_private.request_resources where group_id='{gid}');")
 withdraw(r2);check('imported effective occupancy preserved',occupied()==2)
 sql(f"update atena_private.capacity_pools set occupied=0 where id=(select group_pool_id from atena_private.request_resources where group_id='{gid}');")
 r3=request();r4=request('second');decide(r3);decide(r4)
 sql(f"update atena_private.capacity_pools set occupied=0 where id=(select group_pool_id from atena_private.request_resources where group_id='{gid}');")
 withdraw(r3);check('underreported occupancy respects live confirmations',occupied()==1)
 barrier=threading.Barrier(2)
 def race(qs):
  def run(q):
   barrier.wait();return subprocess.run(cmd,input=auth('begin;'+q+'select pg_sleep(0.15);commit;'),capture_output=True,text=True,encoding='utf-8',timeout=30)
  with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:return list(pool.map(run,qs))
 out=race([f"select public.atena_enrollment_withdraw('{r4}','TEST concurrent withdrawal');"]*2)
 check('concurrent duplicate withdrawals both idempotent',all(x.returncode==0 for x in out))
 check('one audit event and one capacity release',occupied()==0 and sql(f"select count(*) from public.atena_enrollment_withdrawals where request_id='{r4}';")=='1')
 # Withdraw competes with confirmation against the same last seat.
 r5=request();r6=request('second');decide(r5)
 sql(f"update atena_private.capacity_pools set capacity=1 where id=(select group_pool_id from atena_private.request_resources where group_id='{gid}');")
 out=race([f"select public.atena_enrollment_withdraw('{r5}','TEST race withdrawal');",f"select public.atena_request_decide('{r6}','confirmed');"])
 check('withdraw/confirm race has no unexpected failure',out[0].returncode==0 and (out[1].returncode==0 or 'PT409' in out[1].stderr))
 decide(r6);check('last seat consistent after retry',occupied()==1 and sql(f"select count(*) from public.atena_requests where group_id='{gid}' and state='confirmed';")=='1')
 # An extracurricular resource shares a separate activity pool with imported occupancy.
 activity='atena_'+uuid.uuid4().hex*2
 sql(f"insert into atena_private.capacity_pools(id,institution_id,area_id,kind,capacity,occupied) values('activity:{activity}','{inst}','{area}','activity',8,4);update atena_private.request_resources set kind='extracurricular',activity_public_id='{activity}',activity_pool_id='activity:{activity}' where group_id='{gid}';")
 withdraw(r6);check('both group and activity pools release exactly one',occupied()==0 and sql(f"select occupied from atena_private.capacity_pools where id='activity:{activity}';")=='3')
 withdraw(r6);check('activity pool retry never double releases',sql(f"select occupied from atena_private.capacity_pools where id='activity:{activity}';")=='3')
 sql(f"update atena_private.request_resources set kind='curricular',activity_public_id=null,activity_pool_id=null where group_id='{gid}';")
 # Re-create a live enrollment for final revoked-session test.
 r6=request('second');decide(r6)
 saved=sql(f"select decided_by_auth_user_id from public.atena_requests where id='{r6}';")
 sql(f"update public.atena_requests set decided_by_auth_user_id=null where id='{r6}';")
 withdraw(r6,err='23502');check('failed audit insert rolls back capacity release',occupied()==1 and sql(f"select state from public.atena_requests where id='{r6}';")=='confirmed')
 sql(f"update public.atena_requests set decided_by_auth_user_id='{saved}' where id='{r6}';")
 # Identity corrections cannot change authentication, anchors or access links.
 stable={t:digest(t) for t in ['auth.users','auth.sessions','atena_private.applicant_access','atena_private.applicant_links','public.atena_pilot_identity_links','public.atena_pilot_assignments']}
 def payload(target=None,**kw):return dict(scope='family',target_id=target or profiles['adult'],name='TEST rectified adult',birth_date='1990-02-01',reason='TEST documented correction',operation_id=str(uuid.uuid4()),**kw)
 body=payload();correction('apply',body,'stranger','42501');check('foreign profile correction denied')
 correction('apply',body,'unverified','42501');check('unverified email denied')
 correction('apply',{**body,'account_id':users['stranger']},err='22023');check('account/document/link fields not accepted')
 correction('apply',{**body,'target_id':child,'birth_date':'1990-01-01'},err='22023');check('minor cannot become adult through correction')
 correction('apply',{**body,'birth_date':'2016-01-01'},err='22023');check('adult cannot become minor through correction')
 c=correction('apply',body);check('critical correction pending leaves profile intact',sql(f"select name from atena_private.family_profiles where id='{profiles['adult']}';")=='TEST adult')
 check('apply retry stable',correction('apply',body)==c)
 correction('apply',{**body,'name':'TEST changed'},err='PT409');check('conflicting apply retry denied')
 correction('apply',{**body,'operation_id':str(uuid.uuid4())},err='23505');check('duplicate pending correction denied')
 review=dict(application_id=c['application_id'],review_reference='TEST independently verified',identity_checked=True)
 correction('approve',review,'adult','42501');correction('approve',review,'reviewer','42501');check('self and wrong-scope reviewer denied')
 correction('approve',{**review,'identity_checked':False},'familyreview','22023');check('explicit verification required')
 check('stranger sees no correction history',state('stranger')['applications']==[])
 result=correction('approve',review,'familyreview');check('independent family review applies correction',result['status']=='approved' and sql(f"select name from atena_private.family_profiles where id='{profiles['adult']}';")=='TEST rectified adult')
 check('review retry idempotent',correction('approve',review,'familyreview')==result)
 check('critical audit retains previous and proposed values',sql(f"select previous_name||'|'||proposed_name||'|'||status from atena_private.identity_corrections where id='{c['application_id']}';")=='TEST adult|TEST rectified adult|approved')
 c2=correction('apply',{**payload(),'name':'TEST rejected change'});review2={**review,'application_id':c2['application_id']}
 correction('reject',review2,'familyreview');check('rejection leaves profile unchanged',sql(f"select name from atena_private.family_profiles where id='{profiles['adult']}';")=='TEST rectified adult')
 correction('approve',review2,'familyreview','PT409');check('rejected correction cannot approve later')
 ib=dict(scope='institution',target_id=inst,name='TEST corrected institution',reason='TEST institution correction',operation_id=str(uuid.uuid4()))
 correction('apply',ib,'operator','42501');check('non-owner cannot request institutional identity changes')
 ci=correction('apply',ib,'owner');ri={**review,'application_id':ci['application_id']}
 correction('approve',ri,'familyreview','42501');correction('approve',ri,'reviewer');check('institution corrected by independent institutional reviewer')
 wd=json.loads(sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');")))
 check('catalog workspace uses reviewed identity',wd['document']['institution']['name']=='TEST corrected institution')
 check('historical publication not rewritten', 'TEST essential institution' in sql("set role anon;select json_agg(p) from public.atena_catalog_read() p;"))
 check('credentials IDs roles assignments unchanged',all(digest(t)==h for t,h in stable.items()))
 # A guardian cannot self-review even if separately assigned reviewer status.
 cp=correction('apply',{**payload(),'target_id':child,'name':'TEST child corrected','birth_date':'2016-02-01'})
 sql(f"set role service_role;select public.atena_family_reviewer('{users['adult']}',true);")
 correction('approve',{**review,'application_id':cp['application_id']},'adult','42501');check('reviewer cannot approve own guardian correction')
 family('revoke',dict(profile_id=child,user_id=users['adult'],review_reference='TEST revoke guardian'),'familyreview')
 correction('approve',{**review,'application_id':cp['application_id']},'familyreview','42501');check('revoked guardian proposal cannot grant identity change')
 # Stale proposal is rejected instead of overwriting an independently reviewed change.
 stale=correction('apply',{**payload(),'target_id':profiles['second'],'name':'TEST Second corrected'},'second')
 sql(f"update atena_private.family_profiles set name='TEST concurrent reviewed name' where id='{profiles['second']}';")
 correction('approve',{**review,'application_id':stale['application_id']},'familyreview','PT409');check('stale proposal cannot overwrite concurrent identity')
 sql('set role authenticated;select * from atena_private.identity_corrections;'
,'42501');check('critical audit no direct client access')
 sql(f"set role service_role;select public.atena_family_reviewer('{users['familyreview']}',false);")
 pending=correction('apply',{**payload(),'name':'TEST reviewer revoked'})
 correction('approve',{**review,'application_id':pending['application_id']},'familyreview','42501');check('revoked reviewer loses ability immediately')
 operator=sql(f"select id from public.atena_pilot_operators where institution_id='{inst}' and auth_user_id='{users['operator']}';")
 onboarding('revoke_operator',dict(institution_id=inst,operator_id=operator))
 withdraw(r6,'operator',err='42501');check('revoked institutional permissions deny withdrawal with live session',occupied()==1)
 sql(f"delete from auth.sessions where id='{sessions['operator']}';")
 withdraw(r6,'operator',err='42501');check('revoked session cannot withdraw')
 check('enforcement remains OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print(f'SUMMARY {len(checks)} ESSENTIAL OPERATIONS PASS',flush=True)
if __name__=='__main__':main()
