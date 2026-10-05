# Pruebas de concurrencia preparadas — NO EJECUTADAS

No ejecutar en el proyecto remoto ni sobre datos existentes. Requieren PostgreSQL
aislado, base `atena_disposable_candidate`, las migraciones piloto y ambos candidatos
revisados. No hay PostgreSQL/psql/Docker disponible en este entorno. Estas instrucciones
no constituyen evidencia de aceptación ni autorización de una migración.

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
Además de estas pruebas falta validar el contrato HTTP/PostgREST real, pérdida de
respuesta/reintento y dos dispositivos con el adaptador Flutter, todavía no conectado.
