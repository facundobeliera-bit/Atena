"""Session guard candidate on LOCAL fixtures; no remote Auth mutations."""
import argparse,json,pathlib,subprocess,sys,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
A,B,C,D=[f'{i}'*8+'-'+f'{i}'*4+'-4'+f'{i}'*3+'-8'+f'{i}'*3+'-'+f'{i}'*12 for i in range(1,5)]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);args=p.parse_args()
 r=subprocess.run([sys.executable,str(ROOT/'tool/test_catalog_authoring.py'),'--psql',args.psql,'--port',str(args.port)],capture_output=True,text=True,encoding='utf-8',timeout=400)
 assert r.returncode==0,r.stdout+r.stderr
 db=r.stdout.splitlines()[0].split()[1];assert db.startswith('atena_disposable_');print('LOCAL_DB '+db,flush=True)
 cmd=[args.psql,'-X','-qAt','-h','127.0.0.1','-p',str(args.port),'-U','atena_test','-d',db,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];checks=[]
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,text=True,encoding='utf-8',capture_output=True,timeout=30)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 def check(n,ok=True):assert ok,n;checks.append(n);print('PASS '+n,flush=True)
 sql("update public.atena_pilot_assignments set active=true where institution_id='emission-a' and area_id='authoring';")
 # Only LOCAL fixtures simulate the verified remote Auth schema metadata.
 sql("alter table auth.users add column encrypted_password varchar, add column banned_until timestamptz, add column deleted_at timestamptz; create table auth.sessions(id uuid primary key,user_id uuid references auth.users(id),created_at timestamptz not null default clock_timestamp(),not_after timestamptz); update auth.users set encrypted_password='fictional-hash';")
 sid1,sid2,sid3=[str(uuid.uuid4()) for _ in range(3)]
 sql(f"insert into auth.sessions(id,user_id,created_at) values('{sid1}','{A}',now()-interval '1 hour'),('{sid2}','{A}',now()-interval '1 hour'),('{sid3}','{C}',now()-interval '1 hour');")
 sql((ROOT/'supabase/candidates/20261009010000_session_revocation.sql').read_text(encoding='utf-8-sig'));check('migration applies')
 def auth(q,who=A,sid=sid1):return f"set role authenticated;set request.jwt.claim.sub='{who}';set request.jwt.claims='{json.dumps({'sub':who,'session_id':sid})}';"+q
 context='select public.atena_authenticated_context();'
 check('STABLE RPC works in PostgREST read-only transaction',json.loads(sql('begin read only;'+auth(context)+'rollback;'))['auth_user_id']==A)
 for sid in [sid1,sid2]:check('same account independent session accepted '+sid[-4:],json.loads(sql(auth(context,sid=sid)))['session_guard_version']==1)
 sql(auth(context,who=C),'42501');check('session id of another auth user denied')
 sql(auth(context,sid=str(uuid.uuid4())),'42501');check('deleted or invented session denied')
 sql(auth(context,sid='invalid'),'42501');check('malformed session fails closed')
 sql("set role authenticated;set request.jwt.claim.sub='"+A+"';"+context,'42501');check('uid without session claim denied')
 sql(auth(f"select atena_private.revoke_sessions('{C}',true,'administrative');"),'42501');check('operator cannot revoke third party')
 before=sql(auth('select count(*) from public.atena_requests;'))
 sql(f"update auth.users set encrypted_password='fictional-new-hash' where id='{A}';")
 for sid in [sid1,sid2]:sql(auth(context,sid=sid),'42501')
 check('password change blocks both old sessions')
 check('old token direct RLS read returns no private rows',sql(auth('select count(*) from public.atena_requests;'))=='0' and int(before)>0)
 sql(auth("select public.atena_education_read('progreso',null,'emission-a','area-a','00000000-0000-0000-0000-000000000001');"),'42501');check('old token educational RPC blocked')
 fresh=str(uuid.uuid4());sql(f"insert into auth.sessions(id,user_id) values('{fresh}','{A}');")
 check('fresh independent login accepted',json.loads(sql(auth(context,sid=fresh)))['auth_user_id']==A)
 sql(f"update auth.users set encrypted_password='fictional-reset-hash' where id='{A}';")
 sql(auth(context,sid=fresh),'42501');check('password reset revokes fresh prior session')
 fresh=str(uuid.uuid4());sql(f"insert into auth.sessions(id,user_id) values('{fresh}','{A}');")
 sql(f"set role service_role; select atena_private.revoke_sessions('{A}',false,'administrative');")
 sql(auth(context,sid=fresh),'42501');check('trusted administrative revocation blocks prior session')
 fresh=str(uuid.uuid4());sql(f"insert into auth.sessions(id,user_id) values('{fresh}','{A}');")
 sql(f"update auth.users set banned_until=now()+interval '1 day' where id='{A}';")
 sql(auth(context,sid=fresh),'42501');check('disabled auth account denied')
 sql(f"update auth.users set banned_until=null where id='{A}';")
 sql(auth(context,sid=fresh),'42501');check('unban cannot revive historical token')
 fresh=str(uuid.uuid4());sql(f"insert into auth.sessions(id,user_id) values('{fresh}','{A}');")
 sql("update public.atena_pilot_assignments set active=false where institution_id='emission-a' and area_id='area-a';")
 sql(auth("select public.atena_education_enrollments('emission-a','area-a');",sid=fresh),'42501');check('assignment revocation denies still-authenticated user')
 sql("update public.atena_pilot_assignments set active=true,capabilities=array_remove(capabilities,'education.read') where institution_id='emission-a' and area_id='area-a';")
 sql(auth("select public.atena_education_enrollments('emission-a','area-a');",sid=fresh),'42501');check('capability revocation denies read')
 sql(auth('select public.atena_revoke_my_sessions();',sid=fresh));sql(auth(context,sid=fresh),'42501');check('self global cutoff effective immediately on next RPC')
 check('unrelated user remains authorized',json.loads(sql(auth(context,C,sid3)))['auth_user_id']==C)
 sql(f"delete from auth.sessions where id='{sid3}';")
 sql(auth(context,C,sid3),'42501');check('Auth logout session removal denies old JWT claims')
 sid4=str(uuid.uuid4());sql(f"insert into auth.sessions(id,user_id,not_after) values('{sid4}','{D}',now()-interval '1 second');")
 sql(auth(context,D,sid4),'42501');check('expired server session denied')
 sql(f"update auth.sessions set not_after=null where id='{sid4}';update auth.users set deleted_at=now() where id='{D}';")
 sql(auth(context,D,sid4),'42501');check('soft deleted account denied')
 sql(f"update auth.users set deleted_at=null where id='{D}';select atena_private.revoke_sessions('{D}',true,'account_disabled');")
 sid5=str(uuid.uuid4());sql(f"insert into auth.sessions(id,user_id) values('{sid5}','{D}');")
 sql(auth(context,D,sid5),'42501');check('administrative disable denies even a new session')
 sql('set role anon;select * from public.atena_catalog_read();');check('public catalog remains anonymous')
 check('all sensitive executable RPCs guarded',sql("select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'atena_%' and p.proname<>'atena_catalog_read' and has_function_privilege('authenticated',p.oid,'EXECUTE') and position('require_current_session' in p.prosrc)=0;")=='0')
 check('commercial remains OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print('SUMMARY '+str(len(checks))+' SESSION PASS + 205 BASE PASS',flush=True)
if __name__=='__main__':main()
