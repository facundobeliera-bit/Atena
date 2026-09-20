-- Pilot provisioning is server-side only. Client roles remain read-only/RPC-only.
grant select, insert on public.atena_pilot_institutions,
  public.atena_pilot_areas,
  public.atena_pilot_operators,
  public.atena_pilot_assignments,
  public.atena_pilot_operations to service_role;
