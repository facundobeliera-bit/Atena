"""Actual emission RPC regression on a new LOCAL database; no remote option.
SQL claims are fixtures, not proof of JWT authentication. Existing DBs untouched.
"""
import argparse, concurrent.futures, json, pathlib, subprocess, uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
A,B,C,D=[f'{i}'*8+'-'+f'{i}'*4+'-4'+f'{i}'*3+'-8'+f'{i}'*3+'-'+f'{i}'*12 for i in range(1,5)]
MIGRATION=ROOT/'supabase/candidates/20261007000000_shared_calendar_communications.sql'
def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);a=p.parse_args()
    db='atena_disposable_emissions_'+uuid.uuid4().hex[:12]
    base=[a.psql,'-X','-qAt','-h','127.0.0.1','-p',str(a.port),'-U','atena_test','-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose']
    r=subprocess.run(base+['-d','postgres','-c','create database '+db],capture_output=True,text=True);assert r.returncode==0,r.stderr
    print('LOCAL_DB '+db,flush=True);passed=[]
    def sql(q,err=None):
        r=subprocess.run(base+['-d',db],input=q,text=True,encoding='utf-8',capture_output=True,timeout=45)
        assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
        return r.stdout.strip()
    def auth(q,who=A):return f"set role authenticated;set request.jwt.claim.sub='{who}';"+q
    def check(name,ok=True):
        assert ok,name
        passed.append(name);print('PASS '+name,flush=True)
    sql("""create schema auth;create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth,public to anon,authenticated,service_role;
    grant execute on function auth.uid() to anon,authenticated,service_role;
    alter default privileges in schema public grant truncate,references,trigger,maintain on tables to anon,authenticated,service_role;
    alter default privileges in schema public revoke execute on functions from public;""")
    for f in sorted((ROOT/'supabase/migrations').glob('*.sql')):sql(f.read_text(encoding='utf-8-sig'))
    for n in ['20260926000000_catalog_review_only.sql','20260928000000_requests_capacity_review_only.sql','20261006000000_authenticated_context.sql']:
        sql((ROOT/'supabase/candidates'/n).read_text(encoding='utf-8-sig'))
    sql(MIGRATION.read_text(encoding='utf-8-sig'));check('migration applies')
    sql(f"""insert into auth.users values('{A}'),('{B}'),('{C}'),('{D}');
    insert into public.atena_pilot_institutions(id,owner_auth_user_id,display_name) values('emission-a','{A}','School A'),('emission-b','{B}','School B');
    insert into public.atena_pilot_areas(institution_id,id,display_name) values('emission-a','area-a','A'),('emission-a','other','Other'),('emission-b','area-b','B');
    insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name,is_owner) values('emission-a','operator-a','{A}','A',true),('emission-b','operator-b','{B}','B',true);
    insert into public.atena_pilot_identity_links(auth_user_id,local_account_id,institution_id,operator_id,verification_ref,verified_by) values('{A}','pilot-emissions-a','emission-a','operator-a','local-test','local'),('{B}','pilot-emissions-b','emission-b','operator-b','local-test','local');
    insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities) values('emission-a','area-a','operator-a',array['calendar.write','communications.write','responses.read']),('emission-b','area-b','operator-b',array['calendar.write','communications.write','responses.read']);
    insert into atena_private.catalog_namespaces values('emission-a','atena_'||repeat('a',64)),('emission-b','atena_'||repeat('b',64));
    insert into atena_private.catalog_scopes(institution_id,area_id,public_institution_id,public_area_id) values('emission-a','area-a','atena_'||repeat('a',64),'atena_'||repeat('c',64)),('emission-a','other','atena_'||repeat('a',64),'atena_'||repeat('d',64));
    insert into atena_private.applicant_links values('student-c','{C}',true,now()),('student-d','{D}',true,now());
    insert into atena_private.capacity_pools values('pool-a','emission-a','area-a','group',10,1),('pool-other','emission-a','other','group',10,1);
    insert into atena_private.request_resources(group_id,institution_id,area_id,kind,group_pool_id,active) values('atena_'||repeat('e',64),'emission-a','area-a','curricular','pool-a',true),('atena_'||repeat('f',64),'emission-a','other','curricular','pool-other',true);
    insert into public.atena_requests(id,group_id,institution_id,area_id,applicant_profile_id,applicant_auth_user_id,operation_id,state) values
    ('{uuid.UUID(int=1)}','atena_'||repeat('e',64),'emission-a','area-a','student-c','{C}','{uuid.UUID(int=11)}','confirmed'),
    ('{uuid.UUID(int=2)}','atena_'||repeat('e',64),'emission-a','area-a','student-d','{D}','{uuid.UUID(int=12)}','pending'),
    ('{uuid.UUID(int=3)}','atena_'||repeat('f',64),'emission-a','other','student-d','{D}','{uuid.UUID(int=13)}','confirmed');""")
    def save(kind='calendar',ident=20,op=30,revision=0,title='Meeting',requests=(1,),active=True,start="'2026-10-15 10:30'",rsvp='optional'):
        ids=','.join("'"+str(uuid.UUID(int=r))+"'::uuid" for r in requests)
        return f"select public.atena_emission_save('emission-a','area-a','{uuid.UUID(int=ident)}','{uuid.UUID(int=op)}',{revision},'{kind}','{title}','For students',array[{ids}],null,{start},null,'otro','{rsvp}',{str(active).lower()});"
    def student(who=C,profile='student-c',kind='calendar'):
        return json.loads(sql(auth(f"select public.atena_emissions_student('{profile}','{kind}');",who)))
    discover="select public.atena_emission_enrollments('emission-a','area-a');"
    check('recipient discovery excludes pending and other area',[r['profile_id'] for r in json.loads(sql(auth(discover)))]==['student-c'])
    for name,q,who,err in [
      ('foreign institution denied discovery',discover,B,'42501'),('student denied write',save(),C,'42501'),
      ('pending recipient rejected',save(requests=(2,)),A,'42501'),('foreign area rejected',save(requests=(3,)),A,'42501'),
      ('mixed recipients rejected atomically',save(requests=(1,2)),A,'42501'),('missing recipient rejected',save(requests=(999,)),A,'42501'),
      ('missing subject rejected',save(),'', '42501'),('empty title rejected',save(title=' '),A,'22023'),('infinite date rejected',save(start="'infinity'"),A,'22023')]:
        sql(auth(q,who),err);check(name)
    first=json.loads(sql(auth(save())))
    check('publication persists for fresh session',first['delivered']==1 and student()[0]['title']=='Meeting')
    check('other student reads no delivery',student(D,'student-d')==[])
    sql(auth("select public.atena_emissions_student('student-c','calendar');",D),'42501');check('forged profile denied')
    check('no audit or recipient disclosure',not {'snapshot','requests','auth_user_id','created_by_operator_id'}&set(student()[0]))
    check('retry idempotent',json.loads(sql(auth(save())))==first and len(student())==1)
    sql(auth(save(title='Conflict')),'PT409');check('operation payload conflict rejected')
    sql(auth(save(op=31,revision=1,title='Updated')));check('update advances revision',student()[0]['revision']==2 and student()[0]['title']=='Updated')
    sql(auth(save(op=32,revision=1)),'PT409');check('stale revision rejected')
    sql(auth(save(op=32,revision=2),B),'42501');check('foreign institution denied update')
    respond=f"select public.atena_emission_respond('student-c','{uuid.UUID(int=20)}','yes');"
    sql(auth(respond,C));check('RSVP persists',student()[0]['rsvpStatus']=='yes')
    stamp=sql('select responded_at from atena_private.emission_recipients;');sql(auth(respond,C));check('RSVP idempotent',sql('select responded_at from atena_private.emission_recipients;')==stamp)
    sql(auth(respond,D),'42501');check('forged RSVP rejected')
    response="select public.atena_emission_responses('emission-a','area-a');"
    check('institution sees own response',json.loads(sql(auth(response)))[0]['status']=='yes')
    sql(auth(response,B),'42501');check('response isolation')
    for name,change,q,who in [
      ('link revoked',"update public.atena_pilot_identity_links set active=false,revoked_at=now() where operator_id='operator-a';",save(op=40,revision=2),A),
      ('assignment inactive',"update public.atena_pilot_assignments set active=false where operator_id='operator-a';",save(op=40,revision=2),A),
      ('owner contradicts',f"update public.atena_pilot_institutions set owner_auth_user_id='{B}' where id='emission-a';",save(op=40,revision=2),A),
      ('applicant revoked',"update atena_private.applicant_links set active=false where profile_id='student-c';","select public.atena_emissions_student('student-c','calendar');",C)]:
        sql('begin;'+change+auth(q,who)+'rollback;','42501');check(name+' denies access')
    sql(auth(save(kind='communication',ident=21,op=41,start='null',rsvp='none')))
    check('communication plus calendar notice delivered',len(student(kind='communication'))==2)
    check('communication excluded from calendar',len(student())==1)
    hide=f"select public.atena_emission_inbox_state('student-c','{uuid.UUID(int=21)}',true,true);"
    sql(auth(hide,C));check('hide inbox preserves publication',len(student(kind='communication'))==1 and sql('select count(*) from atena_private.institutional_emissions;')=='2')
    sql(auth(hide,D),'42501');check('foreign inbox change rejected')
    sql(auth(save(op=42,revision=2,active=False)));check('withdrawal removes calendar and notification',student()==[] and student(kind='communication')==[])
    check('audit records all accepted versions',sql('select count(*) from atena_private.emission_revisions;')=='4')
    for role in ['anon','authenticated']:
        for table in ['institutional_emissions','emission_recipients','emission_operations','emission_revisions']:
            for verb in ['select * from','truncate']:
                sql(f'set role {role};{verb} atena_private.{table};','42501')
        check(role+' direct access denied')
    sql("set role anon;select public.atena_emissions_student('student-c','calendar');",'42501');check('anonymous RPC denied')
    sql(MIGRATION.read_text(encoding='utf-8-sig'),'42704');check('migration repetition fails atomically',sql('select count(*) from atena_private.emission_revisions;')=='4')
    check('commercial OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
    def race(op):
        r=subprocess.run(base+['-d',db],input=auth(save(op=op,revision=3,title='Concurrent')),capture_output=True,text=True,encoding='utf-8',timeout=30)
        return r.returncode==0,'PT409' in r.stderr
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:result=list(pool.map(race,[50,51]))
    check('concurrent edit exactly one winner',sorted(result)==[(False,True),(True,False)])
    print(f'SUMMARY {len(passed)} PASS',flush=True)
if __name__=='__main__':main()
