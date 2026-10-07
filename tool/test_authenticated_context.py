"""Rehearse the context migration on an EMPTY, disposable LOCAL PostgreSQL DB.

No remote URL/token is accepted. Claims below test SQL authorization, NOT JWT
verification. Real Supabase Auth login must be tested separately before rollout
to Flutter. Never run the fixture setup against a remote project.
"""
import argparse
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/candidates/20261006000000_authenticated_context.sql'
A, B, C, D = [f'{i}' * 8 + '-' + f'{i}' * 4 + '-4' + f'{i}' * 3 +
              '-8' + f'{i}' * 3 + '-' + f'{i}' * 12 for i in range(1, 5)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--psql', required=True)
    parser.add_argument('--port', type=int, default=55440)
    args = parser.parse_args()
    command = [args.psql, '-X', '-qAt', '-h', '127.0.0.1', '-p', str(args.port),
               '-U', 'atena_test', '-d', 'atena_disposable_context',
               '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose']
    checks = []

    def sql(q, expected=None):
        result = subprocess.run(command, input=q, text=True, encoding='utf-8',
                                capture_output=True, timeout=30)
        if expected:
            assert result.returncode != 0 and expected in result.stderr, result.stderr
        else:
            assert result.returncode == 0, result.stderr
        return result.stdout.strip()

    def check(name, assertion):
        assert assertion, name
        checks.append(name)
        print('PASS ' + name, flush=True)

    def context(user, before='', role='authenticated'):
        value = sql(f"begin; {before} set local role {role}; "
                    f"set local request.jwt.claim.sub='{user}'; "
                    'select public.atena_authenticated_context(); rollback;')
        return json.loads(value)

    assert sql("select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace "
               "where n.nspname in ('public','auth','atena_private') and c.relkind='r';") == '0', \
        'REFUSED nonempty DB. Use a new disposable atena_disposable_context.'
    sql("""do $$ begin
      if not exists(select 1 from pg_roles where rolname='anon') then create role anon; end if;
      if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
      if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role bypassrls; end if;
    end $$;
    create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as
      $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth,public to anon,authenticated,service_role;
    grant execute on function auth.uid() to anon,authenticated,service_role;
    """)
    for path in sorted((ROOT / 'supabase/migrations').glob('*.sql')):
        sql(path.read_text(encoding='utf-8-sig'))
    for name in ['20260926000000_catalog_review_only.sql',
                 '20260928000000_requests_capacity_review_only.sql']:
        sql((ROOT / 'supabase/candidates' / name).read_text(encoding='utf-8-sig'))
    # Fingerprint all existing ACLs, RLS flags/policies and routine definitions.
    snapshot = """select jsonb_build_object(
      'tables',(select jsonb_agg(jsonb_build_array(c.oid,c.relacl,c.relrowsecurity,c.relforcerowsecurity) order by c.oid)
        from pg_class c join pg_namespace n on n.oid=c.relnamespace
        where n.nspname in ('public','atena_private') and c.relkind='r'),
      'policies',(select jsonb_agg(to_jsonb(p) order by p.oid) from pg_policy p),
      'functions',(select jsonb_agg(jsonb_build_array(p.oid,p.proacl,pg_get_functiondef(p.oid)) order by p.oid)
        from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname in ('public','atena_private') and p.proname<>'atena_authenticated_context'));
    """
    before = sql(snapshot)
    sql(MIGRATION.read_text(encoding='utf-8-sig'))
    check('existing functions, policies, table permissions and RLS unchanged', sql(snapshot) == before)
    check('commercial enforcement remains OFF', sql('select enforcement_enabled from atena_private.commercial_policy;') == 'f')
    sql(f"""
    insert into auth.users values ('{A}'),('{B}'),('{C}'),('{D}');
    insert into public.atena_pilot_institutions(id,owner_auth_user_id,display_name)
      values ('context-school-a','{A}','Fictitious A'),('context-school-b','{B}','Fictitious B');
    insert into public.atena_pilot_areas(institution_id,id,display_name)
      values ('context-school-a','area-a','Area A'),('context-school-a','unassigned','Unassigned'),
             ('context-school-b','area-b','Area B');
    insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name,is_owner)
      values ('context-school-a','operator-a','{A}','Owner A',true),
             ('context-school-b','operator-b','{B}','Owner B',true);
    insert into public.atena_pilot_identity_links(auth_user_id,local_account_id,institution_id,operator_id,verification_ref,verified_by)
      values ('{A}','pilot-context-owner-a','context-school-a','operator-a','fictional-local-verification','local-test'),
             ('{B}','pilot-context-owner-b','context-school-b','operator-b','fictional-local-verification','local-test');
    insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities)
      values ('context-school-a','area-a','operator-a',array['pilot.read','catalog.publish','requests.read','requests.decide']),
             ('context-school-b','area-b','operator-b',array['requests.read']);
    insert into atena_private.catalog_namespaces values
      ('context-school-a','atena_'||repeat('a',64)),('context-school-b','atena_'||repeat('b',64));
    insert into atena_private.catalog_scopes(institution_id,area_id,public_institution_id,public_area_id) values
      ('context-school-a','area-a','atena_'||repeat('a',64),'atena_'||repeat('c',64)),
      ('context-school-b','area-b','atena_'||repeat('b',64),'atena_'||repeat('d',64)),
      ('context-school-a','unassigned','atena_'||repeat('a',64),'atena_'||repeat('e',64));
    insert into atena_private.applicant_links values
      ('profile-b','{B}',true,now()),('profile-c','{C}',true,now()),('inactive-c','{C}',false,now());
    """)
    a, b, c, d = [context(user) for user in [A, B, C, D]]
    check('A sees exactly own assigned institution/area',
          a['auth_user_id'] == A and a['applicant_profiles'] == [] and
          len(a['institutional_contexts']) == 1 and
          a['institutional_contexts'][0]['institution_id'] == 'context-school-a' and
          a['institutional_contexts'][0]['area_id'] == 'area-a')
    check('capabilities limited to granted operational intersection',
          a['institutional_contexts'][0]['capabilities'] == ['catalog.publish', 'requests.decide', 'requests.read'])
    check('B has own applicant profile and institution only',
          b['auth_user_id'] == B and b['applicant_profiles'] == [{'profile_id': 'profile-b'}] and
          len(b['institutional_contexts']) == 1 and
          b['institutional_contexts'][0]['institution_id'] == 'context-school-b' and
          b['institutional_contexts'][0]['capabilities'] == ['requests.read'])
    check('C applicant cannot acquire institutional privileges',
          c['applicant_profiles'] == [{'profile_id': 'profile-c'}] and c['institutional_contexts'] == [])
    check('unlinked identity obtains no profiles or privileged contexts',
          d == {'auth_user_id': D, 'applicant_profiles': [], 'institutional_contexts': []})
    check('response uses minimal allowlist; no verification records/local account IDs',
          set(a) == {'auth_user_id', 'applicant_profiles', 'institutional_contexts'} and
          set(a['institutional_contexts'][0]) == {'institution_id', 'institution_name', 'area_id',
              'area_name', 'operator_id', 'public_institution_id', 'public_area_id', 'capabilities'})
    for name, q, code in [
        ('anonymous denied', 'set role anon; select public.atena_authenticated_context();', '42501'),
        ('missing subject denied', "set role authenticated; set request.jwt.claim.sub=''; select public.atena_authenticated_context();", '42501'),
        ('malformed subject fails closed', "set role authenticated; set request.jwt.claim.sub='invalid'; select public.atena_authenticated_context();", '22P02'),
        ('arbitrary subject argument not accepted', f"set role authenticated; select public.atena_authenticated_context('{B}');", '42883'),
        ('private applicant mappings remain inaccessible', 'set role authenticated; select * from atena_private.applicant_links;', '42501'),
        ('private catalog mappings remain inaccessible', 'set role authenticated; select * from atena_private.catalog_scopes;', '42501'),
        ('client cannot provision own verified applicant', f"set role authenticated; insert into atena_private.applicant_links values ('forged','{D}',true,now());", '42501'),
    ]:
        sql(q, code)
        check(name, True)
    for name, mutation in [
        ('revoked link', "update public.atena_pilot_identity_links set active=false,revoked_at=now() where operator_id='operator-a';"),
        ('inactive operator', "update public.atena_pilot_operators set active=false where id='operator-a';"),
        ('inactive assignment', "update public.atena_pilot_assignments set active=false where operator_id='operator-a';"),
        ('inactive area', "update public.atena_pilot_areas set active=false where id='area-a';"),
        ('contradictory owner', f"update public.atena_pilot_institutions set owner_auth_user_id='{D}' where id='context-school-a';"),
        ('removed operational capabilities', "update public.atena_pilot_assignments set capabilities=array['pilot.read'] where operator_id='operator-a';"),
    ]:
        check(name + ' immediately removes context', context(A, mutation)['institutional_contexts'] == [])
    check('revoked applicant removed immediately', context(C,
          "update atena_private.applicant_links set active=false where profile_id='profile-c';")['applicant_profiles'] == [])
    nonowner = f"""
      insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name)
        values ('context-school-a','independent-operator','{D}','Independent fictitious operator');
      insert into public.atena_pilot_identity_links(auth_user_id,local_account_id,institution_id,operator_id,verification_ref,verified_by)
        values ('{D}','pilot-independent-context','context-school-a','independent-operator','fixture-independent-verification','local-test');
      insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities)
        values ('context-school-a','area-a','independent-operator',array['requests.read']);
    """
    independent = context(D, nonowner)['institutional_contexts']
    check('non-owner has independent verified identity and only own capabilities',
          len(independent) == 1 and independent[0]['operator_id'] == 'independent-operator' and
          independent[0]['capabilities'] == ['requests.read'])
    check('negative-test mutations rolled back', context(A) == a and context(C) == c and context(D) == d)
    check('only authenticated can execute new RPC', sql("""select
      has_function_privilege('authenticated','public.atena_authenticated_context()','execute') and
      not has_function_privilege('anon','public.atena_authenticated_context()','execute') and
      not exists (select 1 from pg_proc p, aclexplode(p.proacl) acl
        where p.oid='public.atena_authenticated_context()'::regprocedure and acl.grantee=0);""") == 't')
    check('security definer, stable, empty search path, zero arguments', sql("""select
      prosecdef and provolatile='s' and pronargs=0 and proconfig=array['search_path=""']
      from pg_proc where oid='public.atena_authenticated_context()'::regprocedure;""") == 't')
    print(json.dumps({'passed': len(checks), 'scope': 'local PostgreSQL, not JWT login'}))


if __name__ == '__main__':
    main()
