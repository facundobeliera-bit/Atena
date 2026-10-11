"""Local institutional onboarding acceptance tests; never connects remotely."""
import argparse,json,pathlib,subprocess,sys,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);args=p.parse_args()
 base=subprocess.run([sys.executable,str(ROOT/'tool/test_document_retention.py'),'--psql',args.psql,'--port',str(args.port)],capture_output=True,text=True,encoding='utf-8',timeout=500)
 assert base.returncode==0,base.stdout+base.stderr
 db=base.stdout.splitlines()[0].split()[1];assert db.startswith('atena_disposable_');print('LOCAL_DB '+db,flush=True)
 cmd=[args.psql,'-X','-qAt','-h','127.0.0.1','-p',str(args.port),'-U','atena_test','-d',db,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];checks=[]
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,capture_output=True,text=True,encoding='utf-8',timeout=40)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 def check(n,ok=True):assert ok,n;checks.append(n);print('PASS '+n,flush=True)
 def lit(d):return "'"+json.dumps(d).replace("'","''")+"'::jsonb"
 users={n:str(uuid.uuid4()) for n in ['owner','reviewer','other','operator','unverified']};sessions={n:str(uuid.uuid4()) for n in users}
 sql('alter table auth.users add column email text,add column email_confirmed_at timestamptz;')
 for n,u in users.items():sql(f"insert into auth.users(id,email,email_confirmed_at) values('{u}','{n}@example.invalid',"+('null' if n=='unverified' else 'now()')+f");insert into auth.sessions(id,user_id) values('{sessions[n]}','{u}');")
 before=sql('select count(*) from public.atena_pilot_institutions;')
 sql((ROOT/'supabase/candidates/20261010000000_institution_onboarding.sql').read_text(encoding='utf-8-sig'));check('candidate applies without altering institutions',before==sql('select count(*) from public.atena_pilot_institutions;'))
 def auth(q,who='owner'):return f"set role authenticated;set request.jwt.claim.sub='{users[who]}';set request.jwt.claims='{json.dumps({'sub':users[who],'session_id':sessions[who]})}';"+q
 def call(action,data,who='owner',err=None):
  out=sql(auth(f"select public.atena_onboarding_command('{action}',{lit(data)});",who),err)
  return None if err else json.loads(out)
 def state(who='owner'):return json.loads(sql(auth('select public.atena_onboarding_state();',who)))
 def apply(name='TEST nueva institución',reference='test-registry-001',who='owner',err=None,op=None):return call('apply',dict(name=name,reference=reference,operation_id=op or str(uuid.uuid4())),who,err)
 apply(who='unverified',err='42501');check('unverified email denied')
 sql("set role anon;select public.atena_onboarding_state();",'42501');check('anonymous denied')
 sql(auth(f"select public.atena_onboarding_reviewer('{users['owner']}',true);"),'42501');check('cannot self appoint reviewer')
 sql(f"set role service_role;select public.atena_onboarding_reviewer('{users['reviewer']}',true);")
 reviewer_application=apply(name='TEST reviewer self',reference='test-reviewer-self',who='reviewer')
 call('approve',dict(application_id=reviewer_application['application_id'],review_reference='TEST review self',representation_checked=True),'reviewer','42501');check('reviewer cannot approve own institution')

 op=str(uuid.uuid4());a=apply(op=op);check('verified application pending',a['status']=='pending' and state()['institutions']==[])
 check('retry idempotent',apply(op=op)==a)
 apply(err='23505');check('duplicate application rejected')
 apply(name='Different',op=op,err='PT409');check('conflicting retry rejected')
 check('other applicant cannot read request',state('other')['applications']==[])
 decision=dict(application_id=a['application_id'],review_reference='TEST evidence reviewed',representation_checked=True)
 call('approve',decision,err='42501');check('unauthorized approval denied')
 call('approve',{**decision,'representation_checked':False},'reviewer','22023');check('explicit verification required')
 approved=call('approve',decision,'reviewer');inst=approved['institution_id'];check('authorized approval succeeds',approved['status']=='approved')
 check('approval retry same identity',call('approve',decision,'reviewer')['institution_id']==inst)
 owner=state()['institutions'][0];area=owner['areas'][0]['id'];check('owner operator and initial area created',owner['operators'][0]['is_owner'] and owner['operators'][0]['active'])
 context=json.loads(sql(auth('select public.atena_authenticated_context();')));check('server context available',context['institutional_contexts'][0]['institution_id']==inst)
 apply(who='other',err='PT409');check('existing institution cannot be claimed')
 rejected=apply(name='TEST rejected',reference='test-rejected',who='other');rd=dict(application_id=rejected['application_id'],review_reference='TEST evidence insufficient')
 call('reject',rd,'reviewer');call('approve',{**rd,'representation_checked':True},'reviewer','PT409');check('rejected applicant stays unprivileged',state('other')['institutions']==[])
 areaop=str(uuid.uuid4());data=dict(institution_id=inst,name='TEST área nueva',operation_id=areaop)
 newarea=call('area_create',data)['area_id'];check('owner creates area',len(state()['institutions'][0]['areas'])==2)
 check('area retry does not duplicate',call('area_create',data)['area_id']==newarea)
 call('area_create',{**data,'operation_id':str(uuid.uuid4())},'other','42501');check('foreign area creation denied')
 call('area_rename',dict(institution_id=inst,area_id=newarea,name='TEST renombrada'));check('area rename persists',any(x['display_name']=='TEST renombrada' for x in state()['institutions'][0]['areas']))
 invite=dict(institution_id=inst,area_id=area,email='operator@example.invalid',capabilities=['catalog.publish','requests.read','requests.decide'])
 call('invite',{**invite,'capabilities':['admin']},err='42501');check('capability escalation denied')
 invitation=call('invite',invite);iv=dict(invitation_id=invitation['invitation_id'])
 call('accept_invitation',iv,'other','42501');check('invitation bound to verified recipient')
 accepted=call('accept_invitation',iv,'operator');operator=accepted['operator_id'];check('invited operator has scoped context',len(json.loads(sql(auth('select public.atena_authenticated_context();','operator')))['institutional_contexts'])==1)
 call('invite',invite,'operator','42501');check('operator cannot delegate owner authority')
 check('invitation retry safe',call('accept_invitation',iv,'operator')['institution_id']==inst)
 second=call('invite',{**invite,'area_id':newarea,'capabilities':['requests.read']});call('accept_invitation',dict(invitation_id=second['invitation_id']),'operator')
 check('same operator can accept another authorized area',len(json.loads(sql(auth('select public.atena_authenticated_context();','operator')))['institutional_contexts'])==2)

 # Existing publication RPCs must work with server-created identities, without fixture mappings.
 workspace=json.loads(sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');")))
 doc=workspace['document'];gid='atena_'+uuid.uuid4().hex*2
 doc['institution'].update(country='Argentina',province='TEST',city='TEST')
 doc['groups']=[dict(id=gid,kind='curricular',name='Oferta TEST',activity_label='Actividad TEST',schedule='Lunes 10:00-11:00',capacity=2,occupied=0,available=2,availability='available',status='disponible',formal_type='escolar',price='',requirements='TEST',description='TEST',ages='Adultos')]
 published=json.loads(sql(auth(f"select public.atena_catalog_edit('{inst}','{area}','{uuid.uuid4()}',0,0,'publish',{lit(doc)});")))
 check('autonomous publication after approval',published['publication_state']=='published' and gid in sql('set role anon;select json_agg(p) from public.atena_catalog_read() p;'))
 users['student']='33333333-3333-4333-8333-333333333333';sessions['student']=str(uuid.uuid4());sql(f"insert into auth.sessions(id,user_id) values('{sessions['student']}','{users['student']}');")
 request=json.loads(sql(auth(f"select row_to_json(r) from public.atena_request_create('student-c','{gid}','{uuid.uuid4()}') r;",'student')))
 check('approved institution receives new request',sql(auth(f"select count(*) from public.atena_requests where id='{request['id']}';"))=='1')
 sql(auth(f"select public.atena_request_decide('{request['id']}','confirmed');",'other'),'42501')
 confirmed=json.loads(sql(auth(f"select row_to_json(r) from public.atena_request_decide('{request['id']}','confirmed') r;")))
 check('approved owner confirms with capacity enforcement',confirmed['state']=='confirmed')
 check('shared occupancy updated',any(g['id']==gid and g['occupied']==1 and g['available']==1 for pub in json.loads(sql('set role anon;select json_agg(p) from public.atena_catalog_read() p;')) for g in pub['document']['groups']))

 sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');",'other'),'42501');check('foreign publication access denied')
 call('revoke_operator',dict(institution_id=inst,operator_id=operator));check('operator revocation removes context',json.loads(sql(auth('select public.atena_authenticated_context();','operator')))['institutional_contexts']==[])
 sql(auth(f"select public.atena_catalog_workspace('{inst}','{area}');",'operator'),'42501');call('accept_invitation',iv,'operator','42501');check('revoked operator cannot reuse token or invitation')
 call('revoke_operator',dict(institution_id=inst,operator_id=owner['operators'][0]['id']),err='42501');check('owner cannot accidentally revoke itself')
 expired=call('invite',{**invite,'email':'other@example.invalid'});sql(f"update atena_private.operator_invitations set expires_at=now()-interval '1 second' where id='{expired['invitation_id']}';")
 call('accept_invitation',dict(invitation_id=expired['invitation_id']),'other','42501');check('expired invitation denied')
 issuer_invite=call('invite',{**invite,'email':'other@example.invalid'})
 sql(f"update public.atena_pilot_assignments set active=false where institution_id='{inst}' and area_id='{area}' and operator_id='{owner['operators'][0]['id']}';")
 call('accept_invitation',dict(invitation_id=issuer_invite['invitation_id']),'other','42501');check('invitation rechecks issuer current scope')
 sql(f"update public.atena_pilot_assignments set active=true where institution_id='{inst}' and area_id='{area}' and operator_id='{owner['operators'][0]['id']}';")
 pending=apply(name='TEST pending review',reference='test-review-revoked',who='other')
 sql(f"set role service_role;select public.atena_onboarding_reviewer('{users['reviewer']}',false);")
 call('approve',dict(application_id=pending['application_id'],review_reference='TEST review revoked',representation_checked=True),'reviewer','42501');check('revoked reviewer loses approval authority')
 check('all new sensitive client RPCs guard live session',sql("select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'atena_onboarding_%' and has_function_privilege('authenticated',p.oid,'EXECUTE') and position('require_current_session' in p.prosrc)=0;")=='0')

 sql(auth('select * from atena_private.institution_applications;'),'42501');check('direct private table access denied')
 check('audit records retained',int(sql('select count(*) from atena_private.onboarding_audit;'))>=10)
 check('commercial remains OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print(f'SUMMARY {len(checks)} ONBOARDING PASS + 263 BASE PASS',flush=True)
if __name__=='__main__':main()
