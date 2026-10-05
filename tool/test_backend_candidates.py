"""Execute the ACTUAL SQL candidates on a disposable localhost PostgreSQL.

No Supabase URL, credential or network endpoint is accepted. Initialize only an
empty database named atena_disposable_candidate; every run needs a fresh database.
The auth.uid() fixture simulates JWT claims, not GoTrue token verification.
"""
import argparse
import concurrent.futures
import json
import pathlib
import subprocess
import threading

ROOT = pathlib.Path(__file__).resolve().parents[1]
args = argparse.ArgumentParser()
args.add_argument('--psql', required=True)
args.add_argument('--port', type=int, default=55439)
opts = args.parse_args()
command = [opts.psql, '-X', '-qAt', '-h', '127.0.0.1', '-p', str(opts.port),
           '-U', 'atena_test', '-d', 'atena_disposable_candidate',
           '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose']
passed = []


def sql(text, expected=None):
    r = subprocess.run(command, input=text, text=True, encoding='utf-8',
                       capture_output=True, timeout=30)
    if expected:
        assert r.returncode != 0 and expected in r.stderr, r.stderr or r.stdout
    else:
        assert r.returncode == 0, r.stderr
    return r.stdout.strip()


def check(name, text, expected=None):
    result = sql(text, expected)
    passed.append(name)
    print('PASS ' + name, flush=True)
    return result


def auth(text, user='22222222-2222-4222-8222-222222222222'):
    return f"set role authenticated; set request.jwt.claim.sub='{user}';\n" + text


def initialize():
    if sql("select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','auth','atena_private') and c.relkind='r';") != '0':
        raise RuntimeError('REFUSED nonempty database; use a fresh disposable database')
    sql("""do $$ begin
    if not exists(select 1 from pg_roles where rolname='anon') then create role anon; end if;
    if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
    if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role bypassrls; end if;
    end $$;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as
      $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to anon,authenticated,service_role;
    grant execute on function auth.uid() to anon,authenticated,service_role;
    """)
    for path in sorted((ROOT/'supabase/migrations').glob('*.sql')):
        sql(path.read_text(encoding='utf-8-sig'))
    for name in ['20260926000000_catalog_review_only.sql', '20260928000000_requests_capacity_review_only.sql']:
        check('apply ' + name, (ROOT/'supabase/candidates'/name).read_text(encoding='utf-8-sig'))

initialize()
regression = (ROOT/'supabase/tests/requests_capacity_regression.sql').read_text(encoding='utf-8-sig')
check('transactional regression: identity/RLS/retry/terminal/occupancy/revocation', regression)
# Reuse the same public fixture, without duplicating any production operation.
fixture = regression.split('begin;', 1)[1].split('set local role authenticated;', 1)[0]
sql(fixture)
GROUP = 'atena_' + 'c'*64
INST = 'atena_' + 'a'*64
AREA = 'atena_' + 'b'*64
APPLICANT = '11111111-1111-4111-8111-111111111111'
OPERATOR = '22222222-2222-4222-8222-222222222222'
OTHER = '33333333-3333-4333-8333-333333333333'

check('independent non-owner identity accepted', f"""
insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name)
values ('test-request-school','other-operator','{OTHER}','Fictitious independent operator');
insert into public.atena_pilot_identity_links(auth_user_id,institution_id,operator_id,verified_by,verification_ref,local_account_id)
values ('{OTHER}','test-request-school','other-operator','fixture-admin','fixture-verified-independent','pilot-independent');
""")
check('mismatched identity rejected by real trigger', f"""
insert into public.atena_pilot_identity_links(auth_user_id,institution_id,operator_id,verified_by,verification_ref,local_account_id)
values ('{APPLICANT}','test-request-school','other-operator','fixture-admin','fixture-invalid-link','pilot-invalid');
""", '23514')
check('owner condition is enforced without requiring operators to be owners', f"""begin;
update public.atena_pilot_institutions set owner_auth_user_id='{OTHER}' where id='test-request-school';
update public.atena_pilot_identity_links set active=true where operator_id='test-request-operator';
commit;""", '23514')
check('operator without assignment cannot decide/read', auth("do $$ begin if exists(select 1 from public.atena_requests) then raise exception 'leak'; end if; end $$;", OTHER))
sql("update public.atena_pilot_assignments set capabilities=array['catalog.publish','requests.read','requests.decide'];")

payload = dict(schema_version=3, institution=dict(id=INST,name='Fictitious university',city='Demo',province='Demo',country='Demo'),
               area=dict(id=AREA,name='Formal',kind='curricular'),activities=[],groups=[dict(id=GROUP,kind='curricular',name='Program A',
               activity_label='Career',schedule='Monday 08:00',capacity=1,occupied=0,available=1,availability='available',status='disponible',
               formal_type='universidad',price='Gratuito',requirements='Fictitious requirement',description='Public description',ages='Adults')])


def publish(p, op='d', version=0, state='published'):
    raw = json.dumps(p, ensure_ascii=False, separators=(',', ':')).replace("'", "''")
    return auth(f"select public.atena_publish_catalog('test-request-school','test-request-area','{op*64}',{version},encode(sha256(convert_to('{raw}','UTF8')),'hex'),'{raw}','{state}');")


check('public schema3 university/price/requirements publication', publish(payload))
check('publication idempotency', publish(payload))
check('version conflict', publish(payload, 'e', 0), 'PT409')
private = json.loads(json.dumps(payload)); private['institution']['owner_auth_user_id'] = OTHER
check('private field rejected by allowlist', publish(private, 'e', 1), '22023')
legacy = json.loads(json.dumps(payload)); legacy['schema_version'] = 2
for key in ['formal_type','price','requirements','description','ages']: del legacy['groups'][0][key]
legacy_raw = json.dumps(legacy).replace("'", "''")
check('schema2 queued payload remains compatible', f"select atena_private.catalog_validate('{legacy_raw}','{INST}','{AREA}');")
check('anonymous publication visible', "set role anon; do $$ begin if (select count(*) from public.atena_catalog_publications)<>1 then raise exception 'missing'; end if; end $$;")
check('anonymous identity records inaccessible', 'set role anon; select * from public.atena_pilot_identity_links;', '42501')
check('anonymous writes forbidden', "set role anon; update public.atena_catalog_publications set publication_state='withdrawn';", '42501')
check('public RPC rejects invalid pagination', "set role anon; select * from public.atena_catalog_read(-1,200);", '22023')
check('withdrawal versioned', publish(payload, 'e', 1, 'withdrawn'))
check('withdrawal hidden by RLS', "set role anon; do $$ begin if exists(select 1 from public.atena_catalog_publications) then raise exception 'leak'; end if; end $$;")
check('withdrawal hidden by public RPC', "set role anon; do $$ begin if exists(select 1 from public.atena_catalog_read()) then raise exception 'leak'; end if; end $$;")
check('republish versioned', publish(payload, 'f', 2))


def create(profile, operation, group=GROUP):
    return auth(f"select id from public.atena_request_create('{profile}','{group}','{operation}');", APPLICANT)


sql("update atena_private.commercial_policy set enforcement_enabled=true;")
check('server Free denies new request', create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'), '42501')
check('client cannot switch commercial policy', auth('update atena_private.commercial_policy set enforcement_enabled=false;'), '42501')
sql("insert into atena_private.institution_entitlements values ('test-request-school','premium',true);")
first = check('server Premium permits request', create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))
second = check('second pending request before capacity decision', create('test-profile-two','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'))
sql(f"""insert into public.atena_pilot_areas values ('test-request-school','other-area','Other fictitious area',true);
insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities)
 values ('test-request-school','other-area','other-operator',array['requests.read','requests.decide']);
insert into public.atena_pilot_institutions(id,owner_auth_user_id,display_name) values ('foreign-school','{OTHER}','Other fictitious school');
insert into public.atena_pilot_areas values ('foreign-school','foreign-area','Foreign fictitious area',true);
insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name,is_owner)
 values ('foreign-school','foreign-owner','{OTHER}','Foreign owner',true);
insert into public.atena_pilot_identity_links(auth_user_id,institution_id,operator_id,verified_by,verification_ref,local_account_id)
 values ('{OTHER}','foreign-school','foreign-owner','fixture-admin','fixture-foreign-verified','pilot-foreign-owner');
insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities)
 values ('foreign-school','foreign-area','foreign-owner',array['requests.read','requests.decide']);
""")
check('valid foreign-area/institution operator cannot read these pending requests', auth("do $$ begin if exists(select 1 from public.atena_requests) then raise exception 'scope leak'; end if; end $$;", OTHER))
check('valid foreign-area/institution operator cannot decide guessed request ID', auth(f"select public.atena_request_decide('{first}','confirmed');", OTHER), '42501')
sql("update atena_private.institution_entitlements set plan='free';")
assert check('downgrade preserves exact retry', create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')) == first


def race(ids, winners=1):
    barrier = threading.Barrier(2)
    def decide(identifier):
        barrier.wait(timeout=10)
        r = subprocess.run(command, input=auth(f"begin; select id from public.atena_request_decide('{identifier}','confirmed'); select pg_sleep(0.7); commit;"),
                           text=True, encoding='utf-8',capture_output=True,timeout=20)
        return r.returncode, r.stderr
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(decide, ids))
    assert sum(code == 0 for code, _ in results) == winners, results
    if winners == 1: assert any('PT409' in err for _, err in results), results


race([first, second]); passed.append('two simultaneous connections: only one last-seat winner'); print('PASS ' + passed[-1], flush=True)
assert sql("select occupied from atena_private.capacity_pools where id='test-pool';") == '1'
assert sql("select count(*) from public.atena_requests where state='confirmed';") == '1'
check('public reader reflects consumed capacity immediately', "set role anon; do $$ begin if (select document#>>'{groups,0,available}' from public.atena_catalog_read())<>'0' then raise exception 'stale availability'; end if; end $$;")
winner = sql("select id from public.atena_requests where state='confirmed';")
race([winner,winner], winners=2); passed.append('same terminal ID concurrent retries consume only once'); print('PASS ' + passed[-1], flush=True)
check('concurrent winner retry does not consume twice', auth(f"select id from public.atena_request_decide('{winner}','confirmed');"))
assert sql("select occupied from atena_private.capacity_pools where id='test-pool';") == '1'

# Only synthetic fixture data in this disposable database is reset between races.
loser = sql("select id from public.atena_requests where state='pending';")
sql("update atena_private.capacity_pools set occupied=0 where id='test-pool';")
check('confirmed index overrides an underreported counter', auth(f"select public.atena_request_decide('{loser}','confirmed');"), 'PT409')
check('public read uses effective occupancy without double counting', "set role anon; do $$ begin if (select document#>>'{groups,0,occupied}' from public.atena_catalog_read())<>'1' then raise exception 'wrong effective occupancy'; end if; end $$;")
sql("delete from public.atena_requests; update atena_private.capacity_pools set occupied=0,capacity=2; update atena_private.institution_entitlements set plan='premium';")
sql("""insert into atena_private.capacity_pools values ('activity-pool','test-request-school','test-request-area','activity',1,0),
('second-pool','test-request-school','test-request-area','group',2,0);
update atena_private.request_resources set activity_pool_id='activity-pool',kind='extracurricular',activity_public_id='atena_'||repeat('e',64);
insert into atena_private.request_resources values ('atena_'||repeat('d',64),'test-request-school','test-request-area','extracurricular','second-pool','activity-pool',true,'atena_'||repeat('e',64));
update public.atena_catalog_publications set document=jsonb_set(jsonb_set(jsonb_set(document,'{groups,0,kind}','"extracurricular"'),'{groups,0,status}','"activo"'),
 '{activities}',jsonb_build_array(jsonb_build_object('id','atena_'||repeat('e',64),'active',true)));
update public.atena_catalog_publications set document=jsonb_set(document,'{groups}',
 (document->'groups') || jsonb_build_array(jsonb_set(document#>'{groups,0}','{id}',to_jsonb('atena_'||repeat('d',64)))));
""")
first = sql(create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))
second = sql(create('test-profile-two','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'atena_'+'d'*64))
# Different groups share the activity pool: locking must protect it as well.
race([first, second]); passed.append('shared activity capacity serialized'); print('PASS ' + passed[-1], flush=True)
assert sql("select occupied from atena_private.capacity_pools where id='activity-pool';") == '1'
check('public reader reflects shared activity exhaustion for both groups', "set role anon; do $$ begin if exists(select 1 from public.atena_catalog_read() p, jsonb_array_elements(p.document->'groups') g where g->>'available'<>'0') then raise exception 'stale activity availability'; end if; end $$;")

sql("delete from public.atena_requests; update atena_private.capacity_pools set occupied=0; update atena_private.request_resources set activity_pool_id=null; update atena_private.capacity_pools set capacity=0 where id='test-pool';")
check('zero capacity blocks creation', create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'), 'PT409')
sql("update public.atena_pilot_areas set active=false;")
check('inactive area hidden from public RPC', "set role anon; do $$ begin if exists(select 1 from public.atena_catalog_read()) then raise exception 'inactive leak'; end if; end $$;")
check('inactive area prevents new request', create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'), '42501')
sql("update public.atena_pilot_areas set active=true;")
sql("update atena_private.capacity_pools set capacity=2 where id='test-pool';")
barrier = threading.Barrier(2)
def retry_create(_):
    barrier.wait(timeout=10)
    return sql(create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
    same_ids = list(executor.map(retry_create, range(2)))
assert same_ids[0] == same_ids[1]
assert sql('select count(*) from public.atena_requests;') == '1'
passed.append('simultaneous create retry returns one identical request'); print('PASS ' + passed[-1], flush=True)
sql('delete from public.atena_requests;')
sql("update atena_private.capacity_pools set capacity=null where id='test-pool';")
check('unknown extracurricular capacity is not unlimited enrollment', create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'), 'PT409')
sql("update atena_private.capacity_pools set capacity=2 where id='test-pool';")
identifier = sql(create('test-profile-one','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'))
other_id = sql(create('test-profile-two','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'))
sql("update atena_private.capacity_pools set capacity=1 where id='test-pool';")
leader = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True, encoding='utf-8')
leader.stdin.write(auth(f"begin; select id from public.atena_request_decide('{identifier}','confirmed');\n\\echo LOCK_HELD\nselect pg_sleep(1); rollback;\n"))
leader.stdin.close(); leader.stdin = None
while True:
    line = leader.stdout.readline()
    if 'LOCK_HELD' in line: break
    if not line: raise RuntimeError('Rollback leader failed: ' + leader.stderr.read())
check('rollback releases last seat for waiting connection', auth(f"select id from public.atena_request_decide('{other_id}','confirmed');"))
_, leader_error = leader.communicate(timeout=20)
assert leader.returncode == 0, leader_error
assert sql(f"select state from public.atena_requests where id='{identifier}';") == 'pending'
assert sql("select occupied from atena_private.capacity_pools where id='test-pool';") == '1'
sql("update atena_private.capacity_pools set capacity=2 where id='test-pool';")
sql("update public.atena_catalog_publications set document=jsonb_set(document,'{activities,0,active}','false');")
check('inactive activity prevents confirmation', auth(f"select public.atena_request_decide('{identifier}','confirmed');"), 'PT409')
sql(f"insert into atena_private.applicant_links values ('test-profile-three','{APPLICANT}',true,now());")
check('inactive activity prevents new request', create('test-profile-three','cccccccc-cccc-4ccc-8ccc-cccccccccccc'), '42501')
check('inactive activity hides available seats', "set role anon; do $$ begin if exists(select 1 from public.atena_catalog_read() p, jsonb_array_elements(p.document->'groups') g where g->>'availability'<>'suspended') then raise exception 'inactive activity'; end if; end $$;")
sql("update public.atena_catalog_publications set document=jsonb_set(document,'{activities,0,active}','true');")
sql("update atena_private.capacity_pools set capacity=0 where id='test-pool';")
check('capacity reduction is rechecked at confirmation', auth(f"select public.atena_request_decide('{identifier}','confirmed');"), 'PT409')
assert sql(f"select state from public.atena_requests where id='{identifier}';") == 'pending'
sql("update atena_private.capacity_pools set capacity=2 where id='test-pool';")
sql("update atena_private.applicant_links set active=false where profile_id='test-profile-one';")
check('revoked applicant cannot be confirmed', auth(f"select public.atena_request_decide('{identifier}','confirmed');"), '42501')
sql("update public.atena_pilot_identity_links set active=false,revoked_at=now() where operator_id='test-request-operator';")
check('old actor token loses authority', auth(f"select public.atena_request_decide('{identifier}','rejected');"), '42501')
check('revoked publisher denied', publish(payload, '1', 3), '42501')
print(json.dumps({'passed': len(passed), 'remote_operations': 0, 'database': 'localhost disposable PostgreSQL', 'checks': passed}, indent=2))
