"""Rehearse a backup restore in a NEW local disposable database; never Supabase."""
import argparse, hashlib, json, pathlib, re, subprocess, time, uuid
ROOT = pathlib.Path(__file__).resolve().parents[1]

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--pg-bin', required=True, type=pathlib.Path)
    p.add_argument('--source', required=True)
    p.add_argument('--port', type=int, default=55440)
    a = p.parse_args()
    if not re.fullmatch(r'atena_disposable_[a-z0-9_]+', a.source):
        raise ValueError('Only disposable fixture databases are allowed.')
    psql = a.pg_bin / 'psql.exe'
    connection = ['-h', '127.0.0.1', '-p', str(a.port), '-U', 'atena_test']
    def query(db, sql):
        r = subprocess.run([str(psql), '-X', '-qAt', *connection, '-d', db, '-v', 'ON_ERROR_STOP=1', '-c', sql], capture_output=True, text=True, encoding='utf-8', check=True)
        return r.stdout.strip()
    def state(db):
        tables = json.loads(query(db, "select coalesce(json_agg(x order by schemaname,tablename),'[]') from (select schemaname,tablename from pg_tables where schemaname in ('auth','public','atena_private')) x"))
        rows = {}
        for t in tables:
            schema, table = t['schemaname'], t['tablename']
            if not re.fullmatch('[a-z_]+', schema) or not re.fullmatch('[a-z_]+', table):
                raise ValueError('Unexpected test table identifier.')
            rows[schema+'.'+table] = query(db, f"select md5(coalesce(string_agg(row_hash,',' order by row_hash),'')) from (select md5(to_jsonb(t)::text) row_hash from {schema}.{table} t) h")
        def aggregate(sql): return json.loads(query(db, 'select coalesce(json_agg(x),\'[]\') from (' + sql + ') x'))
        return {'rows': rows,
            'policies': aggregate("select * from pg_policies where schemaname in ('public','atena_private') order by schemaname,tablename,policyname"),
            'rls': aggregate("select n.nspname,c.relname,pg_get_userbyid(c.relowner) owner,c.relrowsecurity,c.relforcerowsecurity,coalesce(c.relacl,acldefault('r',c.relowner))::text from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('auth','public','atena_private') and c.relkind='r' order by 1,2"),
            'functions': aggregate("select n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) args,p.prosecdef,p.proconfig,p.prosrc,p.proacl::text from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('auth','public','atena_private') order by 1,2,3"),
            'indexes': aggregate("select * from pg_indexes where schemaname in ('auth','public','atena_private') order by schemaname,tablename,indexname"),
            'sequences': aggregate("select * from pg_sequences where schemaname in ('auth','public','atena_private') order by schemaname,sequencename"),
            'constraints': aggregate("select n.nspname,c.relname,k.conname,pg_get_constraintdef(k.oid) definition,k.convalidated from pg_constraint k join pg_class c on c.oid=k.conrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('auth','public','atena_private') order by 1,2,3"),
            'triggers': aggregate("select n.nspname,c.relname,t.tgname,pg_get_triggerdef(t.oid) definition,t.tgenabled from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where not t.tgisinternal and n.nspname in ('auth','public','atena_private') order by 1,2,3")}
    before = state(a.source)
    directory = ROOT / 'build/recovery'
    directory.mkdir(parents=True, exist_ok=True)
    target = 'atena_disposable_restore_' + uuid.uuid4().hex[:12]
    dump = directory / (target + '.dump')
    started = time.monotonic()
    subprocess.run([str(a.pg_bin/'pg_dump.exe'), *connection, '-d', a.source, '-Fc', '-f', str(dump)], check=True)
    query('postgres', 'create database ' + target)
    subprocess.run([str(a.pg_bin/'pg_restore.exe'), *connection, '-d', target, '--exit-on-error', str(dump)], check=True)
    after = state(target)
    checks = {name: before[name] == after[name] for name in before}
    if not all(checks.values()): raise RuntimeError('Restore differs: ' + str([n for n,v in checks.items() if not v]))
    anonymous = query(target, 'set role anon;select count(*) from public.atena_catalog_read();')
    denial = subprocess.run([str(psql), '-X', '-qAt', *connection, '-d', target, '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose', '-c', 'set role anon;select * from atena_private.document_files;'], capture_output=True, text=True)
    if denial.returncode == 0 or '42501' not in denial.stderr: raise RuntimeError('Expected explicit permission denial after restore.')
    if query(target, 'select enabled from atena_private.document_purge_control;') != 'f': raise RuntimeError('Purge must remain OFF.')
    checks.update(anonymous_catalog=True, private_access_denied=True, purge_off=True)
    result = {'local_only': True, 'source': a.source, 'restored': target, 'checks': checks,
        'table_count': len(before['rows']), 'seconds': round(time.monotonic()-started,2),
        'dump_sha256': hashlib.sha256(dump.read_bytes()).hexdigest(),
        'limits': 'Fictitious local PostgreSQL only. Supabase Auth service, managed ownership, secrets, email and remote disaster recovery NOT certified.'}
    (directory/'result.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result, indent=2))

if __name__ == '__main__': main()
