-- SOLO LECTURA. No es una migración. No ejecutar el script smoke para diagnosticar.
-- Usar únicamente el proyecto piloto y el payload FICTICIO del envío rechazado.
-- No pegar contraseñas, claves ni tokens. No consulta auth.users.

-- 1. Falta contrastar el cuerpo efectivo completo, no repetir propietarios/RLS.
select pg_catalog.pg_get_functiondef(
  'atena_private.pilot_validate_identity_link()'::regprocedure
) as function_sql;

-- 2. Otros BEFORE triggers podrían transformar NEW antes de esta validación.
select t.tgname, t.tgenabled,
       pg_catalog.pg_get_triggerdef(t.oid, true) as trigger_sql
from pg_catalog.pg_trigger t
where t.tgrelid = 'public.atena_pilot_identity_links'::regclass
  and not t.tgisinternal
order by t.tgname;

-- 3. Sustituir sólo estos tres NULL por los valores EXACTOS del JSON rechazado.
-- Si quedan NULL, input_complete=false: el resultado no permite diagnosticar.
-- Sólo devuelve condiciones booleanas, no registros ni información personal.
with input as (
  select null::uuid as auth_user_id,
         null::text as institution_id,
         null::text as operator_id
)
select
  p.auth_user_id is not null and p.institution_id is not null
    and p.operator_id is not null as input_complete,
  exists (select 1 from public.atena_pilot_institutions i
          where i.id = p.institution_id) as institution_exists,
  exists (select 1 from public.atena_pilot_operators o
          where o.institution_id = p.institution_id
            and o.id = p.operator_id) as operator_in_institution,
  exists (select 1 from public.atena_pilot_operators o
          where o.institution_id = p.institution_id
            and o.id = p.operator_id
            and o.auth_user_id = p.auth_user_id) as auth_identity_matches,
  exists (select 1 from public.atena_pilot_operators o
          where o.institution_id = p.institution_id
            and o.id = p.operator_id
            and o.auth_user_id = p.auth_user_id
            and o.active) as matching_operator_active,
  exists (select 1 from public.atena_pilot_operators o
          join public.atena_pilot_institutions i on i.id = o.institution_id
          where o.institution_id = p.institution_id
            and o.id = p.operator_id
            and o.auth_user_id = p.auth_user_id
            and (not o.is_owner or i.owner_auth_user_id = p.auth_user_id))
    as conditional_owner_check,
  exists (select 1 from public.atena_pilot_operators o
          join public.atena_pilot_institutions i on i.id = o.institution_id
          where o.institution_id = p.institution_id
            and o.id = p.operator_id
            and o.auth_user_id = p.auth_user_id
            and o.active
            and (not o.is_owner or i.owner_auth_user_id = p.auth_user_id))
    as complete_local_trigger_predicate,
  exists (select 1 from public.atena_pilot_operators o
          where lower(o.institution_id) = lower(p.institution_id)
            and lower(o.id) = lower(p.operator_id)
            and (o.institution_id <> p.institution_id or o.id <> p.operator_id))
    as case_only_candidate
from input p;

-- Si el predicado completo pasa hoy no prueba el estado de la transacción
-- fallida: contrastar proyecto, payload original y cuerpo efectivo del trigger.
