# Pruebas de concurrencia — ejecutadas localmente el 05/10/2026

No ejecutar en el proyecto remoto ni sobre datos existentes. Requieren PostgreSQL
aislado, base `atena_disposable_candidate`, las migraciones piloto y ambos candidatos
revisados. Se ejecutaron en PostgreSQL 17.11 portátil, sólo localhost, sin servicio
permanente ni conexión a Supabase. Esto no autoriza una migración remota.

El ejecutor reproducible es `tool/test_backend_candidates.py --psql <psql.exe>`.
Sólo acepta localhost, usuario `atena_test` y una base VACÍA llamada
`atena_disposable_candidate` (puerto por defecto 55439). No descarga, borra ni
recrea bases; instala las migraciones/candidatos en esa base y deja las fixtures
ficticias para inspección. Para repetir, preparar otra base desechable vacía.
Simula `auth.uid()` mediante claims locales; no sustituye la validación de JWT
de Supabase Auth/PostgREST.

48 comprobaciones PASS: aplicación de ambos candidatos, regresión transaccional,
identidad de propietario y operador independiente, rechazo de IDs contradictorios,
RLS y capacidades, catálogo schema 2/3, publicación/retiro/versiones/privacidad,
Free/Premium del servidor, cupo efectivo, revocación, aislamiento institucional y
por área, suspensión de actividad, lectura pública de cupos actuales y cinco
casos concurrentes reales: último cupo, actividad compartida entre DOS grupos,
misma confirmación, creación con misma clave y rollback liberando el cupo.

La matriz siguiente conserva casos manuales adicionales (por ejemplo, revocación
en plena transacción y clave simultánea contradictoria). No se declaran ejecutados
por el resultado de 48 comprobaciones. Ninguna prueba de esta unidad fue remota.

La prueba ejecutable de una conexión es `requests_capacity_regression.sql`. Usa
identidades ficticias, exige el nombre de base anterior y revierte sus fixtures.
Comprueba autorización, reintentos, duplicados, transición terminal, ocupación
histórica, sobreocupación, escritura directa denegada y revocación del vínculo.

## Preparación para dos conexiones

En una base desechable vacía, un administrador de pruebas debe persistir únicamente
el bloque de fixtures de `requests_capacity_regression.sql` y dos solicitudes pendientes
mediante `atena_request_create`, una por perfil. No persistir las decisiones del test.
Esto es una preparación diferente al test transaccional, que hace ROLLBACK.
Comprobar que ambas solicitudes existen y que `test-pool` tiene capacidad 1/ocupación 0.

En CADA conexión de decisión ejecutar:

```sql
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub',
  '22222222-2222-4222-8222-222222222222',true);
```

Conexión A, conservar abierta la transacción:

```sql
select (public.atena_request_decide(
  (select id from public.atena_requests where applicant_profile_id='test-profile-one'),
  'confirmed')).state;
```

Conexión B, ejecutar antes del COMMIT de A:

```sql
select (public.atena_request_decide(
  (select id from public.atena_requests where applicant_profile_id='test-profile-two'),
  'confirmed')).state;
```

B debe esperar. Confirmar A con `commit`. B debe rechazar con `PT409`; ejecutar
`rollback` en B. Verificación administrativa en nueva transacción: exactamente
una confirmada, una pendiente y ocupación 1. No aceptar dos PASS simultáneos.

## Variantes bloqueantes

Recrear fixtures en una base desechable para cada variante; no bajar contadores
de un entorno con datos. Registrar salida/SQLSTATE de ambas conexiones sin secretos.

| Variante | Intercalado | Resultado obligatorio |
|---|---|---|
| Misma solicitud | Ambas confirman el ID de perfil uno | Ambas devuelven confirmed; ocupación 1 |
| Dos grupos, actividad compartida | Dos pools de grupo con capacidad 10; ambos recursos extracurriculares apuntan al mismo pool activity de capacidad 1 | Una confirmada; la otra PT409; pool común 1; grupo rechazado 0 |
| Rollback de A | A confirma y luego rollback mientras B espera | B confirma; sólo su solicitud consume cupo |
| Misma clave de operación | Dos create con mismo auth/perfil/grupo/operation_id | Mismo ID, una fila |
| Clave contradictoria | Misma operation_id, distintos perfiles | Una creada, otra 22023 |
| Revocación antes de decidir | Administrador revoca vínculo/asignación y confirma antes de la RPC | 42501, sin cambios |
| Revocación concurrente | A decide y mantiene transacción; B revoca filas de autorización | B espera a A; tras COMMIT de revocación, nuevas decisiones denegadas |
| Retiro del catálogo | Administrador retira publicación antes de confirmar | PT409, solicitud pendiente, cupos intactos |
| Cliente manipulador | JWT familiar intenta decidir; operador de otra institución/área decide el ID conocido | 42501; sin exposición ni cambios |

El test compartido exige un mapeo administrativo real de actividad, nunca inferido
por nombre. La ocupación debe comprobarse contra `greatest(occupied, count(confirmed))`.
Los adaptadores Flutter ya se probaron con SupabaseClient real y un servidor HTTP
de contrato en loopback, incluida respuesta incierta/reintento. Falta ejecutar
Auth/PostgREST remoto y el circuito completo desde dos dispositivos independientes.
