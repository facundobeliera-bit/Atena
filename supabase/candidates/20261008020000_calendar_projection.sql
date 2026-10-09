-- Preserve existing calendar category filters and RSVP controls using server enrollment kind.
begin;
create or replace function public.atena_emissions_student(p_profile text,p_kind text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if not atena_private.request_is_applicant(p_profile) then
    raise exception 'Profile not authorized' using errcode='42501'; end if;
  if p_kind is null or p_kind not in ('calendar','communication') then
    raise exception 'Invalid kind' using errcode='22023'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object(
    'id',e.id,'institucionId',e.institution_id,'institucionNombre',i.display_name,
    'areaId',e.area_id,'grupoId',e.group_id,'title',e.title,'note',e.body,
    'date',to_char(e.starts_at,'YYYY-MM-DD'),'time',to_char(e.starts_at,'HH24:MI'),
    'endDate',to_char(e.ends_at,'YYYY-MM-DD'),'endTime',to_char(e.ends_at,'HH24:MI'),
    'type',g.kind,'tipo','eventoEspecial','tipoEspecial',e.special_type,'source','institucion','locked',true,
    'allowStudentDelete',false,'allowStudentEdit',false,
    'cal_tipo','eventoEspecial','cal_tipoEspecial',e.special_type,
    'requiresRsvp',e.rsvp_policy<>'none','rsvpPolicy',e.rsvp_policy,'rsvpStatus',r.rsvp,
    'revision',e.revision,'createdAt',e.created_at,'read',r.read_at is not null)
    order by e.created_at desc,e.id),'[]'::jsonb)
    from atena_private.emission_recipients r
    join public.atena_requests enrollment on enrollment.id=r.request_id
    join atena_private.request_resources g on g.group_id=enrollment.group_id
    join atena_private.institutional_emissions e on e.id=r.emission_id
    join public.atena_pilot_institutions i on i.id=e.institution_id
    where r.profile_id=p_profile and e.active and
      (e.kind=p_kind or p_kind='communication') and (p_kind='calendar' or not r.hidden));
end; $$;
commit;
