-- Authenticated pilot users may discover only their own active operator and
-- active assignments. This does not change write grants or existing policies.
grant select on public.atena_pilot_operators,
  public.atena_pilot_assignments to authenticated;

create policy atena_pilot_operator_self_read
  on public.atena_pilot_operators for select to authenticated
  using (active and auth_user_id = (select auth.uid()));

create policy atena_pilot_assignment_self_read
  on public.atena_pilot_assignments for select to authenticated
  using (
    active and exists (
      select 1 from public.atena_pilot_operators o
      where o.institution_id = atena_pilot_assignments.institution_id
        and o.id = atena_pilot_assignments.operator_id
        and o.auth_user_id = (select auth.uid())
        and o.active
    ) and exists (
      select 1 from public.atena_pilot_areas a
      where a.institution_id = atena_pilot_assignments.institution_id
        and a.id = atena_pilot_assignments.area_id
        and a.active
    )
  );
