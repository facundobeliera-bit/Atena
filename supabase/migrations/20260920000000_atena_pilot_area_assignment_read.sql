-- An institutional member must not list areas without an active read assignment.
-- Operations already use this same capability check.
drop policy atena_pilot_area_read on public.atena_pilot_areas;
create policy atena_pilot_area_read
  on public.atena_pilot_areas for select to authenticated
  using (atena_private.pilot_can(institution_id, id, 'pilot.read'));
