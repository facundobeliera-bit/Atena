# Activación controlada — 19 de octubre de 2026

Destino exclusivo: Supabase piloto `eaegvxxxkvhdukbkydvy`.
Objetivo: evaluación supervisada ficticia del viernes 23/10. Sin producción,
cuentas reales de alumnos, cambios SMTP/Auth, deployment ni pruebas físicas.

## Evidencia nueva, sólo lectura remota

- Proyecto ACTIVE_HEALTHY. Historial instalado hasta `20261013000000`; las tres
  candidatas del 16/10 siguen ausentes.
- Doce funciones de Atena involucradas coinciden con la base local validada,
  incluidos create/decide y catálogo. Dieciséis tablas/vistas coinciden en columnas,
  constraints y estado RLS. `auth.uid()` local es un fixture: no se equipara a Auth real.
- Referencia de integridad: conteos y huellas de 15 tablas de datos afectadas,
  sin exportar sus filas. Debe releerse justo antes/después de aplicar.
- Escenario reservado «TEST teléfonos»: oferta publicada, recurso activo,
  capacidad 5, ocupación 0, solicitudes activas 0, un vínculo solicitante habilitado.
  Operador propietario activo, propietario coherente y capacidades
  `catalog.publish`, `requests.read`, `requests.decide`. No se modificó el escenario.
- CORS real: OPTIONS HTTP 200 permite el encabezado de contrato para web.
- Cero revisores institucionales/familiares activos. No se designó ninguno.

## Compatibilidad efectiva

Defecto demostrado: el adaptador anterior a `c5a2987` rechaza
`withdrawn_by_institution` como respuesta inválida. No basta ocultar botones.

La candidata `20261016000000` incluye ahora `require_request_contract()`:

1. Sin EXECUTE para bajas y sin eventos de baja, el cliente anterior sigue leyendo
   y operando los estados anteriores. Aplicar la candidata no activa bajas.
2. Con EXECUTE concedido, o si ya existe alguna baja auditada, el servidor exige
   `x-atena-request-contract: 2` en lecturas y mutaciones de solicitudes.
3. RLS restrictiva protege lectura directa de `atena_requests`; create, decide y
   withdraw comprueban el contrato antes de mutar. Se conserva toda su lógica previa.
4. Cliente sin encabezado o con valor incorrecto recibe PT426: «Actualiza Atena
   para consultar o gestionar inscripciones.» No recibe una lista vacía como éxito.
   La UI antigua sanitiza errores y puede mostrar un aviso genérico; la solución
   operativa es actualizar la aplicación, no insistir con el botón de recarga.
5. El cliente actual envía contrato 2 en listar, crear, decidir, baja e historial.
   Android/web usan el mismo adaptador. Los flags de nuevas acciones siguen OFF.
6. El encabezado es negociación de compatibilidad, no prueba de identidad ni de
   integridad del dispositivo. Imitarlo no concede perfiles, roles o capacidades;
   las pruebas de aislamiento rechazan igualmente actores ajenos.
7. Tras una baja, revocar EXECUTE detiene nuevas bajas pero mantiene el bloqueo
   de lectores antiguos. Nunca borrar auditoría para permitir una versión vieja.
8. Las operaciones toman un lock compartido hasta terminar su transacción. La
   activación toma el lock exclusivo y espera a las operaciones anteriores en curso.
   No cambiar el contrato en mitad de una petición antigua que ya fue admitida.

No se garantiza cómo se comporte un cliente modificado arbitrariamente que declare
falsamente otro contrato. Sí se rechazan las versiones distribuidas anteriores que
no lo declaran. No se revocan sus sesiones ni se cambian usuarios.

## Operaciones exactas que requieren autorización

No se ejecutó ninguna de las siguientes escrituras.

### A. Esquema, por separado y en orden

1. `supabase/candidates/20261016000000_enrollment_withdrawal.sql`
   Amplía constraint de estados sin cambiar filas; crea evento/auditoría de baja,
   políticas RLS y función transaccional. Añade guardas de compatibilidad a las
   funciones existentes preservando sus cuerpos, con rechazo ante divergencia.
   Deja EXECUTE de baja revocado para clientes.
2. `supabase/candidates/20261016010000_identity_rectification.sql`
   Crea solicitudes auditadas de rectificación y RPC de revisión; adapta el uso
   del nombre revisado en edición de catálogo. No cambia nombres, fechas, vínculos
   o revisores existentes por aplicar la migración.
3. `supabase/candidates/20261016020000_institution_public_profile.sql`
   Crea ficha pública y eventos privados; RPC de propietario y proyección de
   campos públicos en catálogo. No publica borradores ni reescribe snapshots.

Cada archivo tiene BEGIN/COMMIT. Verificar hash aprobado e historial antes de cada
aplicación; registrar versión sólo tras éxito. No reejecutar ciegamente: creación
de objetos es intencionalmente de una sola aplicación. Ninguno cambia Auth/SMTP,
revisores, conservación, cron, pagos o enforcement comercial.

Después de cada archivo: comparar huellas previas, funciones, RLS/grants y confirmar
que no hay permisos de escritura directa de clientes. Ante error, no continuar con
dependientes. Si la transacción falla, su DDL se revierte. No reconstruir/dropear
tablas ni ejecutar un rollback destructivo sobre datos anteriores.

### B. Activación y campaña ficticia focalizada

Autorización independiente, posterior a A y a verificar clientes compatibles:

```sql
BEGIN;
SELECT pg_advisory_xact_lock(hashtextextended('atena-request-contract',160));
GRANT EXECUTE ON FUNCTION public.atena_enrollment_withdraw(uuid,text) TO authenticated;
COMMIT;
```

Este GRANT activa simultáneamente el control de clientes anteriores. Preparar
cliente compatible antes de concederlo. Mantener recuperación de contraseña OFF.
Autorizar por separado escrituras de la campaña JWT: una oferta/solicitud ficticia,
confirmación, baja con motivo, rectificación solicitada/revisada y edición pública.
No crear usuarios, cambiar credenciales ni otorgar revisores implícitamente.
No consumir el escenario de teléfonos durante pruebas automáticas sin permiso.

Validar con JWT reales: antiguo sin contrato rechazado; contrato correcto con
identidad ajena rechazado; propietario edita; alumno solicita; operador confirma;
una baja libera exactamente una plaza; reintento no duplica evento; carrera de
confirmación/baja; historial y aislamiento; menor no cruza edad por rectificación;
revisor no se autoaprueba. La prueba local no sustituye esta campaña.

Contención no destructiva si falla una operación:

```sql
BEGIN;
SELECT pg_advisory_xact_lock(hashtextextended('atena-request-contract',160));
REVOKE EXECUTE ON FUNCTION public.atena_enrollment_withdraw(uuid,text) FROM authenticated;
COMMIT;
```

Mantener funciones/políticas y lectores compatibles si existen bajas. Conservar
eventos y estados; investigar por operación/UUID sin imprimir tokens. Errores de
perfil se corrigen mediante nueva revisión autorizada. No restaurar sobre el piloto.

## Cuenta administrativa

El propietario identificó su correo personal; la consulta exacta no encontró una
cuenta Auth con ese correo en este proyecto. Los dos alias creados previamente
corresponden a solicitante/revisor ficticios de pruebas, tienen correo confirmado
y solicitudes previas. No se convierten automáticamente en administración personal.

Falta crear/verificar e identificar una cuenta personal separada (o proporcionar
evidencia de otra cuenta personal existente). Después preparar dos operaciones
independientes mediante `tool/onboarding_admin.py`, con UUID verificado y autorización
expresa por alcance. Las pantallas existentes permiten revisión cotidiana sin SQL.
No enviar contraseñas ni enlaces. No se usó la cuenta del incidente.

## Clientes y primer recorrido

Se genera evaluación privada para el mismo proyecto y package Android
`org.atena.evaluation.multiuser`. Instalar encima de la misma aplicación, sin borrar
datos; no confundirla con Atena Demo. No distribuir hasta autorización.

Web completa: `build/evaluation/atena-v1-piloto-web.zip`, con `index.html` y la app.
`auth/return.html` es sólo el retorno de autenticación, no reemplaza la aplicación.
No se publicó ni cambió la URL remota. El servidor local abierto no se considera
actualizado por haber generado el ZIP.

Primer recorrido posterior: institución propietaria → perfil → oferta TEST con cinco
plazas → alumno/responsable autorizado solicita → institución confirma → ambos
actualizan y ven cuatro plazas → baja institucional con motivo → ambos ven cinco
plazas e historial de confirmación/baja. No ejecutado en clientes físicos.

La cuenta personal/revisores no bloquea usar el escenario ya aprobado; sí bloquea
incorporar autónomamente una institución/familia nueva. Recuperación por correo,
privacidad/consentimiento/menores, retención, recuperación integral y soporte siguen
siendo condiciones separadas antes de datos reales. No se reauditaron aquí.

## Validación focalizada

- PostgreSQL local: 67 PASS (59 controles previos afectados y ocho de compatibilidad),
  incluyendo exclusión de peticiones en curso durante la activación.
- Flutter: 45 PASS de solicitudes, cancelación, bajas, sesiones y transporte.
- Análisis de los cuatro archivos Dart modificados: sin incidencias.
- Android/web: PASS; APK y ZIP de evaluación generados y contrastados con su manifiesto.
  Proyecto piloto verificado, recuperación deshabilitada y sin publicación.
- `git diff --check`: PASS. Los 312 archivos protegidos conservan sus hashes.
- No se repitió la suite general ni las campañas remotas JWT históricas.

## Identidad de las candidatas revisadas

SHA-256 del texto UTF-8 normalizado a LF (sin cambiar su SQL):

- `20261016000000_enrollment_withdrawal.sql`: `b46acaae25157e69e434d55e62dc6ed4052af4bc3ccdf83a7d22e4bd385c3f3a`
- `20261016010000_identity_rectification.sql`: `19a7899e6cdceeb19e12240271ff14b2c1936006383c31e7bc36ef9307c14945`
- `20261016020000_institution_public_profile.sql`: `88deb187b0ba46d03e2d3065cc9746e1e40b5f33262267d8a25efd3d3e51fa7f`
