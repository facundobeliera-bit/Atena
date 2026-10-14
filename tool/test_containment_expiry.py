"""Focused LOCAL SQL regression: an Auth ban expiring must not clear Atena disable.

Uses the installed session guard, fictional rows inside a mandatory rollback, and
never accepts a remote host. This is not a live GoTrue refresh-token test.
"""
import argparse
import json
import re
import subprocess
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--psql', required=True)
    parser.add_argument('--database', required=True)
    parser.add_argument('--port', type=int, default=55441)
    args = parser.parse_args()
    if not re.fullmatch(r'atena_disposable_[a-z0-9_]+', args.database):
        raise ValueError('Only an existing disposable local fixture database is allowed.')
    user, old, fresh = [str(uuid.uuid4()) for _ in range(3)]
    claims = json.dumps({'sub': user, 'session_id': fresh})
    script = f"""
begin;
insert into auth.users(id,email,email_confirmed_at)
values('{user}','containment@example.invalid',now());
insert into auth.sessions(id,user_id,created_at)
values('{old}','{user}',now()-interval '1 hour');
set local role authenticated;
set local request.jwt.claim.sub='{user}';
set local request.jwt.claims='{json.dumps({'sub': user, 'session_id': old})}';
do $$ begin
 if not atena_private.session_allowed() then raise exception 'Valid baseline session denied'; end if;
end $$;
select 'PASS baseline session allowed before containment';
reset role;
select atena_private.revoke_sessions('{user}',true,'administrative');
update auth.users set banned_until=now()-interval '1 second' where id='{user}';
insert into auth.sessions(id,user_id,created_at)
values('{fresh}','{user}',clock_timestamp()+interval '1 second');
set local role authenticated;
set local request.jwt.claim.sub='{user}';
set local request.jwt.claims='{claims}';
do $$ begin
 if atena_private.session_allowed() then raise exception 'Fresh session recovered private access'; end if;
end $$;
select 'PASS fresh session blocked after Auth ban expiry';
do $$ begin
 begin
  perform public.atena_family_state();
  raise exception 'Family RPC unexpectedly accepted';
 exception when insufficient_privilege then null; end;
 begin
  perform public.atena_authenticated_context();
  raise exception 'Context RPC unexpectedly accepted';
 exception when insufficient_privilege then null; end;
 begin
  perform public.atena_family_command('apply','{{}}'::jsonb);
  raise exception 'Family write unexpectedly accepted';
 exception when insufficient_privilege then null; end;
end $$;
select 'PASS private reads and writes reject disabled account';
set local request.jwt.claims='{json.dumps({'sub': user, 'session_id': old})}';
do $$ begin
 if atena_private.session_allowed() then raise exception 'Old session recovered access'; end if;
end $$;
select 'PASS old session remains blocked';
reset role;
select atena_private.revoke_sessions('{user}',false,'self_logout');
do $$ begin
 if not (select disabled from atena_private.session_security where auth_user_id='{user}')
 then raise exception 'Later cutoff cleared disable'; end if;
end $$;
select 'PASS subsequent revocation cannot clear disable';
rollback;
do $$ begin
 if exists(select 1 from auth.users where id='{user}')
 or exists(select 1 from auth.sessions where user_id='{user}')
 or exists(select 1 from atena_private.session_security where auth_user_id='{user}')
 then raise exception 'Fixture persisted'; end if;
end $$;
select 'PASS rollback leaves no fixtures';
"""
    result = subprocess.run([args.psql, '-X', '-qAt', '-h', '127.0.0.1',
        '-p', str(args.port), '-U', 'atena_test', '-d', args.database,
        '-v', 'ON_ERROR_STOP=1'], input=script, capture_output=True,
        text=True, encoding='utf-8', timeout=45)
    if result.returncode:
        raise RuntimeError(result.stderr)
    checks = [line for line in result.stdout.splitlines() if line.startswith('PASS ')]
    if len(checks) != 6:
        raise RuntimeError('Incomplete local containment regression.')
    print('\n'.join(checks))
    print('6 local containment checks PASS; no remote Auth request or token replay.')


if __name__ == '__main__':
    main()
