"""Run educational RPC regression only on a freshly created LOCAL emissions DB."""
import argparse,concurrent.futures,json,pathlib,subprocess,sys,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]
A,B,C,D=[f'{i}'*8+'-'+f'{i}'*4+'-4'+f'{i}'*3+'-8'+f'{i}'*3+'-'+f'{i}'*12 for i in range(1,5)]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);a=p.parse_args()
 base_run=subprocess.run([sys.executable,str(ROOT/'tool/test_shared_emissions.py'),'--psql',a.psql,'--port',str(a.port)],capture_output=True,text=True,encoding='utf-8',timeout=180)
 assert base_run.returncode==0,base_run.stdout+base_run.stderr
 db=base_run.stdout.splitlines()[0].split()[1];assert db.startswith('atena_disposable_emissions_')
 print('LOCAL_DB '+db,flush=True)
 cmd=[a.psql,'-X','-qAt','-h','127.0.0.1','-p',str(a.port),'-U','atena_test','-d',db,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];checks=[]
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,text=True,encoding='utf-8',capture_output=True,timeout=30)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 def auth(q,who=A):return f"set role authenticated;set request.jwt.claim.sub='{who}';"+q
 def check(n,ok=True):
  assert ok,n
  checks.append(n);print('PASS '+n,flush=True)
 def lit(x):return "'"+json.dumps(x,ensure_ascii=False).replace("'","''")+"'::jsonb"
 migration=ROOT/'supabase/candidates/20261008000000_shared_education.sql'
 sql(migration.read_text(encoding='utf-8-sig'));check('education migration applies')
 sql("update public.atena_pilot_assignments set capabilities=capabilities||array['education.read','education.write'] where operator_id='operator-a';")
 check('existing granted calendar capability retained','calendar.write' in json.loads(sql(auth('select public.atena_authenticated_context();')))['institutional_contexts'][0]['capabilities'])
 samples={'progreso':{'porcentaje':40},'boletines':{'anio':2026,'periodo':'Primero','calificaciones':{'Matemática':8},'observaciones':'Publicable'},'titulos':{'titulo':'Certificado TEST','entidadEmisora':'Ficticia','fechaEmision':'2026-10-08T00:00:00.000'},'becas':{'nombre':'Beca TEST','descripcion':'Ficticia','fechaInicio':'2026-10-08T00:00:00.000','fechaFin':None,'activa':True},'sanciones':{'motivo':'TEST','tipo':'Advertencia','detalle':'Ficticio','fecha':'2026-10-08T00:00:00.000','hasta':None,'activa':True},'equivalencias':{'institucionOrigenId':'ficticia','materiaOrigen':'TEST A','materiaDestino':'TEST B','observacion':'Decisión ficticia','fecha':'2026-10-08T00:00:00.000','aprobada':True}}
 def save(module,data=None,revision=0,ident=None,op=None,visible=True,req=1):
  return f"select public.atena_education_save('emission-a','area-a','{uuid.UUID(int=req)}','{ident or 'record-'+module}','{module}','{op or uuid.uuid4()}',{revision},{lit(samples[module] if data is None else data)},{str(visible).lower()});"
 def read(module,who=C,profile='student-c'):
  return json.loads(sql(auth(f"select public.atena_education_read('{module}','{profile}');",who)))
 def institution(module):
  return json.loads(sql(auth(f"select public.atena_education_read('{module}',null,'emission-a','area-a','{uuid.UUID(int=1)}');")))
 for module,data in samples.items():
  op=uuid.uuid4();q=save(module,op=op,visible=False);first=json.loads(sql(auth(q)))
  check(module+' private draft hidden from student',read(module)==[] and len(institution(module))==1)
  check(module+' retry idempotent',json.loads(sql(auth(q)))==first)
  sql(auth(save(module,revision=1)))
  rows=read(module);check(module+' published data persists to independent connection',len(rows)==1 and rows[0]['revision']==2)
  check(module+' private history not exposed','historial' not in rows[0] and 'auth_user_id' not in rows[0] and 'created_by_operator_id' not in rows[0])
  check(module+' institutional audit preserves draft',len(institution(module)[0]['historial'])==1 and institution(module)[0]['historial'][0]['visibleAlumno']==False)
  check(module+' other student isolated',read(module,D,'student-d')==[])
  sql(auth(save(module,revision=2),B),'42501');check(module+' foreign institutional write denied')
  sql(auth(save(module,revision=2),C),'42501');check(module+' student write denied')
  sql(auth(save(module,revision=1)),'PT409');check(module+' stale edit rejected')
  sql(auth(save(module,{**data,'notaInterna':'private'},revision=2)),'22023');check(module+' unexpected private field rejected')
  sql(auth(save(module,revision=2,visible=False)));check(module+' withdrawal takes effect',read(module)==[])
 for name,q,who,err in [
  ('forged profile read',"select public.atena_education_read('progreso','student-c');",D,'42501'),
  ('foreign institution read',f"select public.atena_education_read('progreso',null,'emission-a','area-a','{uuid.UUID(int=1)}');",B,'42501'),
  ('pending enrollment',save('progreso',ident='pending',req=2),A,'42501'),
  ('other area enrollment',save('progreso',ident='other-area',req=3),A,'42501'),
  ('duplicate progress',save('progreso',ident='progress-duplicate'),A,'23505'),
  ('duplicate report period',save('boletines',ident='report-duplicate'),A,'23505'),
  ('out of range progress',save('progreso',{'porcentaje':101},revision=3),A,'22023'),
  ('wrong boolean type',save('becas',{**samples['becas'],'activa':'true'},revision=3),A,'22023'),
  ('missing mandatory title',save('titulos',{**samples['titulos'],'titulo':''},revision=3),A,'22023'),
  ('reversed dates',save('becas',{**samples['becas'],'fechaFin':'2025-01-01'},revision=3),A,'22023'),
  ('fake complete report',save('boletines',{'anio':2026,'periodo':'Primero','calificaciones':{},'completo':True},revision=3),A,None),
 ]:
  sql(auth(q,who),err);check(name)
 check('report completeness derived by server',institution('boletines')[0]['completo']==False)
 for name,change,q,who in [
  ('revoked applicant',"update atena_private.applicant_links set active=false where profile_id='student-c';","select public.atena_education_read('progreso','student-c');",C),
  ('revoked operator',"update public.atena_pilot_identity_links set active=false,revoked_at=now() where operator_id='operator-a';",save('progreso',revision=3),A),
  ('contradictory owner',f"update public.atena_pilot_institutions set owner_auth_user_id='{B}' where id='emission-a';",save('progreso',revision=3),A)]:
  sql('begin;'+change+auth(q,who)+'rollback;','42501');check(name+' revalidated')
 for role in ['anon','authenticated']:
  for table in ['education_records','education_revisions','education_operations']:
   for verb in ['select * from','truncate']:
    sql(f'set role {role};{verb} atena_private.{table};','42501')
  check(role+' direct table privileges absent')
 sql("set role anon;select public.atena_education_read('progreso','student-c');",'42501');check('anonymous read denied')
 def race(v):
  r=subprocess.run(cmd,input=auth(save('progreso',{'porcentaje':v},revision=3)),capture_output=True,text=True,encoding='utf-8',timeout=30)
  return r.returncode==0,'PT409' in r.stderr
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:result=list(pool.map(race,[60,80]))
 check('concurrent educational edit one winner',sorted(result)==[(False,True),(True,False)])
 check('commercial OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print(f'SUMMARY {len(checks)} EDUCATION PASS + 41 EMISSIONS PASS',flush=True)
if __name__=='__main__':main()
