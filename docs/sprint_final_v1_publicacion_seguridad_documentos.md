# Sprint final V1 — publicación, sesiones y documentos

> Informe histórico del 09/10. Las tres migraciones se aplicaron después; NO volver a ejecutarlas.
> Estado actual y preparación: [preparacion_evaluacion_v1.md](preparacion_evaluacion_v1.md).

Fecha: 09/10/2026. Base: `82f1e1dd731ea2326323c915f168a080898b0079`.
Estado: implementación local validada; activación remota pendiente de autorización.
No se aplicaron migraciones remotas, revocaciones ni purgas. Sin deployment.

## A. Oferta educativa

El catálogo institucional habitual permite crear/editar grupos en el área autorizada,
guardar borradores privados, publicar y retirar. Reutiliza la proyección de catálogo,
los recursos, las reservas y los pools existentes; no crea una segunda oferta.
El editor remoto evita ejecutar los formularios de persistencia SharedPreferences:
usa los mismos campos del contrato público, dentro de la pantalla actual de catálogo.
Incluye actividad/programa, grupo/turno, horario, edades, condiciones y capacidad.

El servidor obtiene el operador de Auth y comprueba vínculo, propietario y asignación
vigentes. Provisiona únicamente el namespace/scope de esa área autorizada cuando se
guarda por primera vez. Un área sin publicación previa aparece en el contexto.
Borradores y recibos de idempotencia no tienen acceso directo desde clientes.
El control de revisión rechaza ediciones concurrentes obsoletas. Al publicar se
bloquean recursos/pools y se usa ocupación efectiva, nunca la enviada por Flutter.
No puede reducirse capacidad por debajo de confirmaciones; retirar conserva solicitudes.
La lectura para edición adapta schema 2 sin reescribir la publicación histórica.
Editar no reactiva una actividad suspendida; guardar tras retirar no republica.
Antes de aplicar el candidato remoto, el cliente conserva el contrato anterior y
avisa que falta habilitar edición; errores de red/identidad no activan almacenamiento local.

## B. Sesiones

La protección candidata verifica `auth.uid()` + `session_id` del JWT contra
`auth.sessions`, estado del usuario y corte de sesiones anterior a un cambio sensible.
Un trigger de Auth registra cambios de contraseña, restablecimientos, bloqueo y
eliminación lógica. La migración no modifica usuarios ni sesiones existentes.
Sólo la administración confiable puede revocar terceros; el RPC de usuario sólo revoca
su propia identidad. Flutter muestra cierre global únicamente si el contexto devuelve
`session_guard_version = 1`: primero corte server-side, después logout global de Auth.
La pérdida de capacidad institucional sigue siendo independiente de cerrar Auth.

Los RPC sensibles se protegen antes de ejecutar su lógica/idempotencia. Las tablas
públicas privadas agregan una política RESTRICTIVE, conservando sus reglas previas.
El catálogo publicado sigue siendo anónimo. Los RPC de escritura serializan con
cambios de Auth; los STABLE y las lecturas RLS verifican el snapshot sin escrituras ni
locks incompatibles con transacciones READ ONLY de PostgREST.

Límites: una lectura ya iniciada puede terminar con su snapshot anterior; una escritura
ya autorizada puede terminar antes de que confirme la revocación. La operación siguiente
se rechaza. No se retira información ya recibida, copiada o guardada fuera de Atena.
No hay detección instantánea en una pantalla inactiva sin nueva petición; ante el rechazo
explícito de sesión, Flutter limpia Auth y el Navigator existente descarta las vistas privadas.
Un fallo de permisos de área o de red no se interpreta como revocación global.
La protección nueva requiere aplicación remota y validación con JWT reales: no basta
el logout del cliente ni revocar solamente refresh tokens.

Referencias: [sesiones de Supabase](https://supabase.com/docs/guides/auth/sessions),
[logout](https://supabase.com/docs/guides/auth/signout),
[transacciones de PostgREST](https://postgrest.org/en/stable/references/transactions.html).

## C. Retención y purga

El almacenamiento vigente es BYTEA en PostgreSQL privado, no un bucket Storage.
No se cambia esa arquitectura. Cinco días vencen el acceso; no autorizan la purga.

| Tipo | Política inicial |
| --- | --- |
| DNI, partida, CUIL, domicilio y libreta sanitaria | Desactivada; plazo y fecha de aplicación requieren decisión del propietario. |
| Boletín adjunto | Conservar; el mecanismo rechaza activar su purga automática. |
| Otro | Conservar por ambigüedad; no asumir que carece de valor educativo. |
| Títulos, boletines y demás registros de módulos educativos | Fuera de la purga; no se modifican. |

Cada política tiene fecha de aplicación: no alcanza documentos anteriores por defecto.
La purga exige acceso vencido Y plazo de retención cumplido, tipo habilitado, ausencia
de retención especial, contenido presente y habilitación global administrativa.
Lotes de 20 (máximo 100), SKIP LOCKED, auditoría y eliminación de bytes en una sola
transacción. Un fallo revierte todo el lote; reintentos y ejecuciones concurrentes son seguros.
Cada archivo tiene un único id/solicitud, sin claves de objetos compartidos; fingerprints
no se utilizan como referencias a objetos. Se mantiene el historial y los metadatos
(id, tipo, propietario, MIME, hash, fechas y solicitud) para trazabilidad.
La auditoría automática agrega sólo id, fecha, bytes eliminados y regla de retención.
La política cubre la purga automática; conserva la acción explícita existente del alumno
para eliminar sus adjuntos. `legal_hold` impide purga automática, no reemplaza una política
legal integral ni cambia unilateralmente el contrato de eliminación manual.

La prueba verifica ausencia de contenido en el almacenamiento activo. No promete borrado
seguro de versiones MVCC, WAL ni backups: sus plazos y anonimización requieren decisión aparte.
No se permite al alumno/operador configurar ni invocar el proceso privado.

Preparada función de programación con job fijo `atena-private-document-purge`, horario
`17 * * * *`, lote 20, y desprogramación idempotente. No instala extensiones ni crea jobs
al migrar. pg_cron está disponible pero no instalado en el piloto; ejecución real del
scheduler pendiente. Se probó el rechazo seguro cuando falta esa dependencia, no un
job cron real. [Contrato de jobs nombrados](https://supabase.com/docs/guides/cron/quickstart).

## Aplicación pendiente: operación exacta y orden

En el proyecto piloto `eaegvxxxkvhdukbkydvy`, ejecutar íntegramente, una sola vez y
con rol administrativo de migraciones, los archivos siguientes, por orden:

1. `supabase/candidates/20261009000000_catalog_authoring.sql`
2. `supabase/candidates/20261009010000_session_revocation.sql`
3. `supabase/candidates/20261009020000_document_retention.sql`

Cada archivo incluye BEGIN/COMMIT. No usar un push genérico de todas las migraciones.
Dependen del catálogo, solicitudes, contexto, calendario, educación y documentos actuales.
Las 43 funciones instaladas siguen coincidiendo con la base previa; no hay drift detectado.
B agrega trigger en Auth y protección RLS: requiere autorización específica; no disminuye
el aislamiento. C crea políticas OFF y no ejecuta purga ni programa job.

Después: autorizar campaña ficticia de publicación/solicitud/confirmación/retiro y
revocación de dos sesiones de una misma cuenta ficticia. Validar con JWT reales y
reintentos. No reutilizar ni consumir el escenario reservado para teléfonos sin indicación.
La activación de retención/cron es una autorización SEPARADA: acordar plazos por tipo,
fecha prospectiva, tratamiento de metadata/backups y permitir instalación de pg_cron.
No se proporciona una orden de activación con plazos inventados.
Reversión lógica: conservar datos y candidatos, no ejecutar DROP masivos; detener
programación/purga deshabilitando su control si en el futuro se autorizara activarla.

## Validación realizada

- Flutter: **461 PASS, 0 omitidas** (448 base + 7 publicación + 6 revocación).
- PostgreSQL: **311 PASS**: 175 módulos existentes + 30 publicación + 28 sesiones +
  30 retención + 48 catálogo/cupos. Bases locales nuevas y desechables.
- Incluye aislamiento negativo, propietario, revocación, READ ONLY, borradores privados,
  ediciones concurrentes, última vacante con dos conexiones y un único ganador,
  idempotencia, retención, fallo de almacenamiento transaccional y reintento de purga.
- Supabase actual: **42 lecturas PASS con Auth/JWT reales**; escenario físico intacto.
  Esto NO prueba las nuevas migraciones en remoto. No se alteraron usuarios/contraseñas.
- Análisis: **76 avisos históricos, ninguno nuevo**; exit 1 por esos avisos.
- Web JavaScript y APK release: PASS. Avisos WASM de dependencias existentes; no se afirma build WASM.
- `git diff --check`: PASS. Escaneo de patrones, contraseñas ficticias conocidas en memoria,
  historial Git y artefactos: sin hallazgos. No es garantía absoluta de ausencia de secretos.
- Los 312 archivos históricos/diagnóstico protegidos conservaron sus hashes.
- Enforcement comercial OFF; ninguna nueva dependencia ni cambio de precios/pagos.

APK parcial: `build/atena-v1-evaluacion-parcial-publicacion-seguridad-documentos.apk`.
SHA256: `AB4F81C3233219FB0AA13FD9297EE4E325B91CCD502E02D4E3F7D1EC06814722`.
Paquete separado `org.atena.evaluation.multiuser`, configuración pública del piloto.
No instalado ni validado físicamente; sin deployment. No constituye versión de producción.

Antes de congelar V1: aprobar/aplicar los tres candidatos, probar sus operaciones con
JWT reales y dos dispositivos, decidir retención/cron y verificar la presentación completa
de ofertas, cambio/revocación de sesiones y documentos. Si retención permanece OFF,
explicitar ese pendiente en lugar de declarar purga automática operativa.
