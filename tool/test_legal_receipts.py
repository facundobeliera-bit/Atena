"""Focused LOCAL PostgreSQL test. Claims/guards are fixtures, not real Auth/JWT.
Requires an already healthy local PostgreSQL and anon/authenticated/service_role.
Never contacts Supabase; keeps its disposable database for inspection.
"""
import argparse
import json
from pathlib import Path
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--psql', required=True)
    parser.add_argument('--port', type=int, default=55441)
    args = parser.parse_args()
    db = 'atena_disposable_legal_' + uuid.uuid4().hex[:12]
    base = [args.psql, '-X', '-qAt', '-h', '127.0.0.1', '-p', str(args.port),
            '-U', 'atena_test', '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose']
    def sql(query, error=None, database=db):
        result = subprocess.run(base + ['-d', database], input=query, text=True,
            encoding='utf-8', capture_output=True, timeout=30)
        if error:
            assert result.returncode != 0 and error in result.stderr, 'Expected SQLSTATE ' + error
        else:
            assert result.returncode == 0, 'Local SQL failed; inspect disposable database'
        return result.stdout.strip().splitlines()[-1] if result.stdout.strip() else ''
    assert sql("select count(*) from pg_roles where rolname in ('anon','authenticated','service_role');", database='postgres') == '3', 'Existing local test roles required'
    sql('create database ' + db, database='postgres')
    print('LOCAL_DB ' + db)
    a, b, unverified = [str(uuid.uuid4()) for _ in range(3)]
    sql(f"""
      create schema auth; create schema atena_private;
      create table auth.users(id uuid primary key, verified boolean, active boolean default true);
      insert into auth.users(id,verified) values('{a}',true),('{b}',true),('{unverified}',false);
      create function auth.uid() returns uuid language sql stable as $$
        select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
      create function atena_private.require_current_session_read() returns void language plpgsql security definer as $$
      begin if not exists(select 1 from auth.users where id=auth.uid() and active) then
      raise exception 'Session rejected' using errcode='42501';end if;end;$$;
      create function atena_private.require_current_session() returns void language sql security definer as $$
      select atena_private.require_current_session_read() $$;
      create function atena_private.onboarding_verified_email() returns void language plpgsql security definer as $$
      begin if not exists(select 1 from auth.users where id=auth.uid() and verified) then
      raise exception 'Unverified' using errcode='42501';end if;end;$$;
    """)
    sql((ROOT/'supabase/candidates/20261027000000_legal_receipts_review_only.sql').read_text(encoding='utf-8'))
    checks = []
    def check(name, condition=True):
        assert condition, name
        checks.append(name)
        print('PASS ' + name)
    def actor(user, query, error=None):
        return sql(f"set role authenticated;set request.jwt.claim.sub='{user}';" + query, error)
    def document(version, kind='specific_consent', key='fictitious_consent'):
        return sql(f"insert into atena_private.legal_documents(document_key,version,revision,kind,audience,purpose,body,valid_from,approved) values('{key}','{version}',{version},'{kind}','family','FICTITIOUS TEST','TEST ONLY - NOT LEGAL TEXT',now()-interval '1 minute',true) returning id;")
    d = document(1)
    digest = sql(f"select content_sha256 from atena_private.legal_documents where id='{d}';")
    def record(user=a, doc=d, fingerprint=digest, action='accept', operation=None, explicit='true', error=None):
        op = operation or str(uuid.uuid4())
        return actor(user, f"select public.atena_legal_record('{doc}','{fingerprint}','{action}','{op}',{explicit});", error)
    check('disabled by default', json.loads(actor(a,'select public.atena_legal_state();'))['enabled'] is False)
    record(error='55000');check('receipt creation cannot activate itself')
    sql('update atena_private.legal_receipt_control set enabled=true;')  # this disposable DB only
    record(explicit='false',error='22023');record(explicit='null',error='22023');check('explicit action mandatory')
    record(user=unverified,error='42501');check('unverified rejected')
    record(fingerprint='wrong',error='22023');check('content mismatch rejected')
    op = str(uuid.uuid4());receipt = json.loads(record(operation=op))
    check('server actor and timestamp', receipt['actor']==a and bool(receipt['recorded_at']))
    check('retry same receipt', json.loads(record(operation=op))['id']==receipt['id'])
    record(action='withdraw',operation=op,error='23505');check('operation cannot change meaning')
    check('other user cannot see receipt', json.loads(actor(b,'select public.atena_legal_state();'))['receipts']==[])
    record(user=b,action='withdraw',error='42501');check('cannot withdraw another identity consent')
    for role in ['anon','authenticated']:
        for table in ['legal_documents','legal_receipts','legal_receipt_control']:
            sql(f'set role {role};select * from atena_private.{table};','42501')
        check(role+' has no direct table access')
    sql("set role anon;select public.atena_legal_state();",'42501');check('anonymous cannot invoke RPC')
    sql(f"update atena_private.legal_documents set body='different' where id='{d}';",'42501')
    sql(f"delete from atena_private.legal_receipts where id='{receipt['id']}';",'42501')
    check('content and historical receipt immutable')
    sql(f"update atena_private.legal_documents set approved=false where id='{d}';")
    record(error='22023');check('unpublished cannot be accepted')
    record(action='withdraw');check('own consent can be withdrawn after unpublishing')
    sql(f"update atena_private.legal_documents set approved=true where id='{d}';")
    newer = document(2)
    record(error='22023');check('superseded version rejected')
    state = json.loads(actor(a,'select public.atena_legal_state();'))
    check('new version offered without deleting historical receipts',state['documents'][0]['id']==newer and len(state['receipts'])==2)
    contract = document(1,'contract_acceptance','fictitious_contract')
    record(doc=contract,action='accept')
    record(doc=contract,action='withdraw',error='42501');check('contract distinct from specific consent')
    sql(f"update auth.users set active=false where id='{a}';")
    actor(a,'select public.atena_legal_state();','42501');record(error='42501')
    check('revoked session cannot read or record')
    check('all new tables RLS enabled',sql("select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='atena_private' and c.relname like 'legal_%' and c.relkind='r' and c.relrowsecurity;")=='3')
    print(f'SUMMARY {len(checks)} LOCAL SQL PASS; fixture guards, not Auth proof')

if __name__ == '__main__':
    main()
