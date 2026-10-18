-- LOCAL CANDIDATE ONLY. Explicit remote approval required.
-- Depends on family onboarding (20261013000000). No backfill or Auth changes.
begin;
alter table public.atena_requests drop constraint atena_requests_state_check;
alter table public.atena_requests add constraint atena_requests_state_check
 check(state in ('pending','confirmed','rejected','cancelled_by_student','cancelled_by_institution','withdrawn_by_institution'));
create table public.atena_enrollment_withdrawals (
 request_id uuid primary key references public.atena_requests(id),
 institution_id text not null, area_id text not null,
 confirmed_at timestamptz not null,
 confirmed_by_auth_user_id uuid not null references auth.users(id),
 confirmed_by_operator_id text not null,
 withdrawn_at timestamptz not null default clock_timestamp(),
 withdrawn_by_auth_user_id uuid not null references auth.users(id),
 withdrawn_by_operator_id text not null,
 reason text not null check(length(btrim(reason)) between 8 and 300),
 foreign key(institution_id,confirmed_by_operator_id) references public.atena_pilot_operators(institution_id,id),
 foreign key(institution_id,withdrawn_by_operator_id) references public.atena_pilot_operators(institution_id,id)
);
alter table public.atena_enrollment_withdrawals enable row level security;
revoke all on public.atena_enrollment_withdrawals from public,anon,authenticated,service_role;
grant select on public.atena_enrollment_withdrawals to authenticated;
create policy withdrawal_visible_request on public.atena_enrollment_withdrawals for select to authenticated
 using(exists(select 1 from public.atena_requests r where r.id=request_id));
create policy withdrawal_live_session on public.atena_enrollment_withdrawals as restrictive for all to authenticated
 using((select atena_private.session_allowed())) with check((select atena_private.session_allowed()));
create function public.atena_enrollment_withdraw(p_request_id uuid,p_reason text)
returns public.atena_enrollment_withdrawals language plpgsql volatile security definer set search_path='' as $$
declare r public.atena_requests%rowtype; e public.atena_enrollment_withdrawals%rowtype;
 g atena_private.request_resources%rowtype; pool atena_private.capacity_pools%rowtype;
 op text; n bigint; reason text:=btrim(p_reason);
begin
 perform atena_private.require_current_session();
 if reason is null or length(reason) not between 8 and 300 then raise exception 'Withdrawal reason required' using errcode='22023';end if;
 select * into r from public.atena_requests where id=p_request_id;
 if not found then raise exception 'Request unavailable' using errcode='42501';end if;
 -- Same live authorization locks/order as request confirmation. No client actor IDs.
 select o.id into op from public.atena_pilot_operators o
 join public.atena_pilot_institutions i on i.id=o.institution_id
 join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
 join public.atena_pilot_assignments a on a.institution_id=o.institution_id and a.operator_id=o.id
 join public.atena_pilot_areas ar on ar.institution_id=a.institution_id and ar.id=a.area_id
 where o.institution_id=r.institution_id and a.area_id=r.area_id and o.auth_user_id=auth.uid()
 and o.active and l.active and l.revoked_at is null and a.active and ar.active
 and (not o.is_owner or i.owner_auth_user_id=o.auth_user_id) and 'requests.decide'=any(a.capabilities)
 for share of o,i,l,a,ar;
 if op is null then raise exception 'Institutional decision permission required' using errcode='42501';end if;
 select * into strict r from public.atena_requests where id=p_request_id for update;
 select * into e from public.atena_enrollment_withdrawals where request_id=r.id;
 if found then
  if e.reason<>reason then raise exception 'Conflicting withdrawal retry' using errcode='PT409';end if;
  return e;
 end if;
 if r.state<>'confirmed' then raise exception 'Confirmed enrollment required' using errcode='PT409';end if;
 select * into strict g from atena_private.request_resources where group_id=r.group_id;
 -- Preserve imported occupancy: exactly one effective enrollment is released.
 -- Count BEFORE changing state, under the same sorted pool locks as confirmation.
 for pool in select * from atena_private.capacity_pools
 where id=g.group_pool_id or id=g.activity_pool_id order by id for update loop
  select count(*) into n from public.atena_requests q
  join atena_private.request_resources resource on resource.group_id=q.group_id
  where q.state='confirmed' and (resource.group_pool_id=pool.id or resource.activity_pool_id=pool.id);
  if n<1 then raise exception 'Inconsistent confirmed occupancy' using errcode='23514';end if;
  update atena_private.capacity_pools set occupied=greatest(pool.occupied,n)-1 where id=pool.id;
 end loop;
 insert into public.atena_enrollment_withdrawals(request_id,institution_id,area_id,confirmed_at,
 confirmed_by_auth_user_id,confirmed_by_operator_id,withdrawn_by_auth_user_id,withdrawn_by_operator_id,reason)
 values(r.id,r.institution_id,r.area_id,r.updated_at,r.decided_by_auth_user_id,r.decided_by_operator_id,auth.uid(),op,reason)
 returning * into e;
 -- Original confirmation fields remain unchanged. The separate event records the exit.
 update public.atena_requests set state='withdrawn_by_institution',updated_at=e.withdrawn_at where id=r.id;
 return e;
end; $$;
revoke all on function public.atena_enrollment_withdraw(uuid,text) from public,anon,authenticated,service_role;
-- Deliberately NOT granted to clients yet. Activation requires a separate,
-- explicitly approved GRANT after incompatible clients have been retired.
-- UI feature flags alone cannot protect readers from an unknown terminal state.
commit;
