"""Retention/purge on a fresh disposable LOCAL database; never deletes remotely."""
import argparse,concurrent.futures,json,pathlib,subprocess,sys,uuid
ROOT=pathlib.Path(__file__).resolve().parents[1]

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--psql',required=True);p.add_argument('--port',type=int,default=55440);a=p.parse_args()
 prev=subprocess.run([sys.executable,str(ROOT/'tool/test_session_revocation.py'),'--psql',a.psql,'--port',str(a.port)],capture_output=True,text=True,encoding='utf-8',timeout=600)
 assert prev.returncode==0,prev.stdout+prev.stderr
 db=prev.stdout.splitlines()[0].split()[1];assert db.startswith('atena_disposable_');print('LOCAL_DB '+db,flush=True)
 cmd=[a.psql,'-X','-qAt','-h','127.0.0.1','-p',str(a.port),'-U','atena_test','-d',db,'-v','ON_ERROR_STOP=1','-v','VERBOSITY=verbose'];checks=[]
 def sql(q,err=None):
  r=subprocess.run(cmd,input=q,text=True,encoding='utf-8',capture_output=True,timeout=30)
  assert (r.returncode!=0 and err in r.stderr) if err else r.returncode==0,r.stderr or r.stdout
  return r.stdout.strip()
 def check(n,ok=True):assert ok,n;checks.append(n);print('PASS '+n,flush=True)
 before=sql('select md5(coalesce(json_agg(t order by id)::text,\'\')) from (select id,content,deleted from atena_private.document_files) t;')
 sql((ROOT/'supabase/candidates/20261009020000_document_retention.sql').read_text(encoding='utf-8-sig'));check('migration applies inactive')
 check('no previous bytes changed',before==sql('select md5(coalesce(json_agg(t order by id)::text,\'\')) from (select id,content,deleted from atena_private.document_files) t;'))
 check('all seven types disabled',sql('select count(*) from atena_private.document_retention_policy where not enabled and retention_days is null;')=='7')
 check('no scheduler extension installed automatically',sql("select count(*) from pg_extension where extname='pg_cron';")=='0')
 sql('select atena_private.configure_document_purge_schedule(true);','55000');check('missing scheduler fails explicitly')
 for role in ['anon','authenticated']:
  for q in ['select atena_private.purge_expired_documents();','select * from atena_private.document_purge_candidates();','select atena_private.configure_document_purge_schedule(true);','update atena_private.document_purge_control set enabled=true;','select * from atena_private.document_purge_audit;']:
   sql('set role '+role+';'+q,'42501')
  check(role+' cannot inspect or activate purge')
 def fixture(kind='dni',age=10,expired=True,hold=False):
  id=str(uuid.uuid4())
  sql(f"insert into atena_private.document_requests(id,request_id,institution_id,area_id,profile_id,kind,message,state,operator_id) values('{id}','00000000-0000-0000-0000-000000000001','emission-a','area-a','student-c','{kind}','TEST ONLY','cumplida','operator-a'); insert into atena_private.document_files(id,content,mime,fingerprint,uploaded_at,expires_at,legal_hold) values('{id}',convert_to('%PDF-FICTITIOUS','UTF8'),'application/pdf','test',now()-interval '{age} days',now()+interval '{-1 if expired else 1} days',{str(hold).lower()});")
  return id
 current=fixture(expired=False);eligible=fixture();retained=fixture('boletin');general=fixture('otro');young=fixture(age=6);held=fixture(hold=True);historical=fixture(age=100)
 check('access expiry alone cannot delete',sql('select atena_private.purge_expired_documents();')=='0')
 # Explicit LOCAL test policy, not a proposed legal/functional production deadline.
 sql("update atena_private.document_retention_policy set enabled=true,retention_days=7,applies_from=now()-interval '30 days' where kind='dni';")
 check('dry run exact eligible one',sql('select document_id from atena_private.document_purge_candidates();')==eligible)
 check('global switch still disabled',sql('select atena_private.purge_expired_documents();')=='0')
 sql("update atena_private.document_retention_policy set enabled=true,retention_days=7 where kind='boletin';",'23514');check('educational retention cannot accidentally enable')
 sql("update atena_private.document_retention_policy set enabled=true,retention_days=7 where kind='otro';",'23514');check('ambiguous document type remains retained')
 sql('update atena_private.document_purge_control set enabled=true;')
 for limit in [0,101]:sql(f'select atena_private.purge_expired_documents({limit});','22023')
 check('batch bounds enforced')
 sql("create function atena_private.test_purge_failure() returns trigger language plpgsql as $$begin raise exception 'Fictitious temporary storage failure';end;$$;create trigger test_purge_failure before insert on atena_private.document_purge_audit for each row execute function atena_private.test_purge_failure();")
 sql('select atena_private.purge_expired_documents();','P0001')
 check('failure keeps bytes and metadata atomically',sql(f"select content is not null and not deleted from atena_private.document_files where id='{eligible}';")=='t' and sql('select count(*) from atena_private.document_purge_audit;')=='0')
 sql('drop trigger test_purge_failure on atena_private.document_purge_audit;drop function atena_private.test_purge_failure();')
 check('retry deletes eligible content only',sql('set role service_role;select atena_private.purge_expired_documents();')=='1')
 check('effective active storage deletion',sql(f"select content is null and deleted from atena_private.document_files where id='{eligible}';")=='t')
 check('audit minimal and consistent',sql(f"select count(*) from atena_private.document_purge_audit where document_id='{eligible}' and bytes_removed={len(b'%PDF-FICTITIOUS')} and retention_days=7;")=='1')
 for id,label in [(current,'still accessible'),(retained,'educational'),(general,'ambiguous'),(young,'retention not elapsed'),(held,'legal hold'),(historical,'predates approval')]:
  check(label+' preserved',sql(f"select content is not null and not deleted from atena_private.document_files where id='{id}';")=='t')
 check('repeat is idempotent',sql('select atena_private.purge_expired_documents();')=='0')
 check('historical request metadata remains',sql(f"select state from atena_private.document_requests where id='{eligible}';")=='cumplida')
 # A second request cannot share the file's primary key; fingerprints are not object pointers.
 sql(f"insert into atena_private.document_files select * from atena_private.document_files where id='{current}';",'23505');check('shared object identity rejected')
 ids=[fixture() for _ in range(3)]
 def worker(_):return sql('select atena_private.purge_expired_documents(2);')
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:counts=list(pool.map(worker,range(2)))
 check('concurrent batches remove exactly eligible total',sum(map(int,counts))==3)
 check('one audit per removed object',sql('select count(*) from atena_private.document_purge_audit;')=='4')
 sql('update atena_private.document_purge_control set enabled=false;');fixture()
 check('disable stops future batches',sql('select atena_private.purge_expired_documents();')=='0')
 check('commercial remains OFF',sql('select enforcement_enabled from atena_private.commercial_policy;')=='f')
 print(f'SUMMARY {len(checks)} RETENTION PASS; preceding chain: '+prev.stdout.splitlines()[-1],flush=True)
if __name__=='__main__':main()
