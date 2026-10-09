"""Private temporary documents regression on a fresh disposable LOCAL database."""
import argparse,base64,json,pathlib,subprocess,sys,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
A,B,C,D=[f'{i}'*8+'-'+f'{i}'*4+'-4'+f'{i}'*3+'-8'+f'{i}'*3+'-'+f'{i}'*12 for i in range(1,5)]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);a=p.parse_args()
 prev=subprocess.run([sys.executable,str(ROOT/'tool/test_shared_education.py'),'--psql',a.psql,'--port',str(a.port)],capture_output=True,text=True,encoding='utf-8',timeout=240)
 assert prev.returncode==0,prev.stdout+prev.stderr
 db=prev.stdout.splitlines()[0].split()[1];assert db.startswith('atena_disposable_');print('LOCAL_DB '+db,flush=True)
 cmd=[a.psql,'-X','-qAt','-h','127.0.0.1','-p',str(a.port),'-U','atena_test','-d',db,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];checks=[]
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,text=True,encoding='utf-8',capture_output=True,timeout=30)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 def auth(q,who=A):return f"set role authenticated;set request.jwt.claim.sub='{who}';"+q
 def check(n,ok=True):
  assert ok,n
  checks.append(n);print('PASS '+n,flush=True)
 sql((ROOT/'supabase/candidates/20261008010000_shared_documents_notifications.sql').read_text(encoding='utf-8'))
 check('documents migration applies')
 sql((ROOT/'supabase/candidates/20261008020000_calendar_projection.sql').read_text(encoding='utf-8'))
 check('calendar projection migration applies')
 sql("update public.atena_pilot_assignments set capabilities=capabilities||array['documents.read','documents.write'] where operator_id='operator-a';")
 ident=str(uuid.uuid4());enrollment=str(uuid.UUID(int=1));pdf=base64.b64encode(b'%PDF-1.4 fictitious test only').decode()
 def request(id=ident,req=enrollment):return f"select public.atena_document_request('emission-a','area-a','{req}','{id}','otro','TEST only');"
 def read(who=C,profile='student-c'):return json.loads(sql(auth(f"select public.atena_documents_read('{profile}');",who)))
 def upload(content=pdf,who=C,id=ident,profile='student-c',err=None):return sql(auth(f"select public.atena_document_upload('{profile}','{id}','{content}');",who),err)
 check('institution requests',sql(auth(request()))==ident)
 check('request retry idempotent',sql(auth(request()))==ident)
 check('student reads own request',read()['requests'][0]['id']==ident)
 check('another student sees none',read(D,'student-d')=={'requests':[],'documents':[]})
 sql(auth(request(str(uuid.uuid4()))),'23505');check('duplicate pending kind denied')
 sql(auth(request(str(uuid.uuid4())),B),'42501');check('foreign institution denied')
 sql(auth(request(str(uuid.uuid4())),C),'42501');check('student cannot request')
 sql(auth(request(str(uuid.uuid4()),str(uuid.UUID(int=2)))),'42501');check('unconfirmed enrollment denied')
 sql(auth("select public.atena_documents_read('student-c');",D),'42501');check('forged profile denied')
 sql(auth("select public.atena_documents_read(null,'emission-a','area-a');",B),'42501');check('foreign institution read denied')
 upload(who=D,err='42501');check('wrong student cannot upload')
 upload(content=base64.b64encode(b'<html>not a file').decode(),err='22023');check('wrong magic rejected')
 upload(content='A'*2796205,err='22023');check('oversize rejected')
 check('student uploads',upload()==ident)
 check('same upload idempotent',upload()==ident)
 upload(content=base64.b64encode(b'%PDF-different').decode(),err='PT409');check('replacement rejected')
 r=read();check('fulfilled atomically',r['requests'][0]['estado']=='cumplida' and len(r['documents'])==1)
 check('metadata excludes bytes and private audit','base64' not in json.dumps(r) and 'fingerprint' not in json.dumps(r) and 'operator_id' not in json.dumps(r))
 for who,label in [(A,'institution'),(C,'student')]:
  x=json.loads(sql(auth(f"select public.atena_document_open('{ident}');",who)))
  check(label+' opens authorized bytes',base64.b64decode(x['base64'])==base64.b64decode(pdf))
 for who,label in [(B,'other institution'),(D,'other student')]:
  sql(auth(f"select public.atena_document_open('{ident}');",who),'42501');check(label+' cannot open private bytes')
 sql(auth(f"select public.atena_document_cancel('{ident}');"),'PT409');check('fulfilled request cannot cancel')
 for change,q,who,label in [
  ("update atena_private.applicant_links set active=false where profile_id='student-c';",f"select public.atena_document_open('{ident}');",C,'revoked student'),
  ("update public.atena_pilot_identity_links set active=false,revoked_at=now() where operator_id='operator-a';",f"select public.atena_document_open('{ident}');",A,'revoked operator'),
  (f"update public.atena_pilot_institutions set owner_auth_user_id='{B}' where id='emission-a';",f"select public.atena_document_open('{ident}');",A,'contradictory owner')]:
  sql('begin;'+change+auth(q,who)+'rollback;','42501');check(label+' denied')
 sql(f"update atena_private.document_files set expires_at=now()-interval '1 second' where id='{ident}';")
 sql(auth(f"select public.atena_document_open('{ident}');",C),'PT404');check('server expiry denies bytes')
 check('expired metadata visible',read()['documents'][0]['estado']=='expirado')
 check('expired cleanup',sql(auth("select public.atena_documents_remove('student-c',null,true);",C))=='1')
 check('expired bytes cleared',sql(f"select content is null and deleted from atena_private.document_files where id='{ident}';")=='t')
 check('cleanup idempotent',sql(auth("select public.atena_documents_remove('student-c',null,true);",C))=='0')
 second=str(uuid.uuid4());sql(auth(request(second)));sql(auth(f"select public.atena_document_cancel('{second}');"));sql(auth(f"select public.atena_document_cancel('{second}');"));check('cancellation idempotent')
 upload(id=second,err='PT409');check('cancelled upload denied')
 third=str(uuid.uuid4());sql(auth(request(third)));upload(id=third)
 sql(auth(f"select public.atena_documents_remove('student-d','{third}',false);",D),'42501');check('cannot delete another profile file')
 sql(auth(f"select public.atena_documents_remove('student-c','{third}',false);",C));sql(auth(f"select public.atena_document_open('{third}');",A),'PT404');check('deletion reflected in other session')
 for role in ['anon','authenticated']:
  for table in ['document_requests','document_files','document_audit']:
   sql(f'set role {role};select * from atena_private.{table};','42501')
  check(role+' direct tables denied')
 sql("set role anon;select public.atena_documents_read('student-c');",'42501');check('anonymous RPC denied')
 notice_before=int(sql('select count(*) from atena_private.institutional_emissions;'))
 rev=sql("select revision from atena_private.education_records where id='record-progreso';")
 q=f"select public.atena_education_save('emission-a','area-a','{enrollment}','record-progreso','progreso','{uuid.uuid4()}',{rev},jsonb_build_object('porcentaje',55),true);"
 sql(auth(q));sql(auth(q));check('one generic notice for published education retry',int(sql('select count(*) from atena_private.institutional_emissions;'))==notice_before+1)
 check('generic notice exposes no educational data',json.loads(sql(auth("select public.atena_emissions_student('student-c','communication');",C)))[0]['note']=='Tu institución compartió una actualización. Consultá tu trayectoria educativa.')
 # Withdrawal must remain possible after the confirmed enrollment is cancelled.
 e=str(uuid.uuid4())
 publish=f"select public.atena_emission_save('emission-a','area-a','{e}','{uuid.uuid4()}',0,'calendar','TEST','Test',array['{enrollment}'::uuid],null,'2026-10-15'::timestamp);"
 sql(auth(publish));check('calendar retains curricular category',json.loads(sql(auth("select public.atena_emissions_student('student-c','calendar');",C)))[0]['type']=='curricular');sql(f"update public.atena_requests set state='cancelled_by_student' where id='{enrollment}';")
 withdrawal=f"select public.atena_emission_save('emission-a','area-a','{e}','{uuid.uuid4()}',1,'calendar','TEST','Test',array['{enrollment}'::uuid],null,'2026-10-15'::timestamp,null,'otro','none',false);"
 sql(auth(withdrawal));check('withdrawal after cancelled enrollment succeeds')
 sql(auth(f"select public.atena_emission_save('emission-a','area-a','{uuid.uuid4()}','{uuid.uuid4()}',0,'calendar','TEST','Test',array['{enrollment}'::uuid],null,'2026-10-15'::timestamp);"),'42501');check('new delivery to cancelled enrollment remains forbidden')
 check('commercial enforcement OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print(f'SUMMARY {len(checks)} DOCUMENTS PASS + 88 EDUCATION PASS + 41 EMISSIONS PASS',flush=True)
if __name__=='__main__':main()
