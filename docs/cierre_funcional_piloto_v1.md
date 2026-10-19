# Cierre funcional local del primer piloto — 18/10/2026

Actualización 19/10: `activacion_piloto_20261019.md` registra la comparación remota
de dependencias y el control de contrato de solicitudes probado localmente. Ese
plan prevalece sobre el requisito anterior de retirar manualmente todos los clientes.

## Resultado y límites

Esta unidad completa la ficha pública institucional y endurece la activación de
bajas ya implementadas. No cambia Supabase remoto, Auth, usuarios, SMTP ni permisos
remotos. No hay deployment ni pruebas manuales/físicas. No se declara producción lista.

## Perfil institucional público

Carencia reproducida: el adaptador remoto descartaba dirección, teléfono y
presentación; el catálogo sólo incluía ubicación por oferta. No había una operación
central para editar contacto institucional.

Candidata `20261016020000_institution_public_profile.sql`:
- Reutiliza sesión vigente, correo confirmado, identidad institucional y propietario
  verificados por `onboarding_owner`. Un operador común, revisor, familiar u otra
  institución no puede editar la ficha. No se agrega ningún rol ni capacidad.
- Campos públicos permitidos: nombre de presentación, descripción, país, provincia,
  localidad, dirección, teléfono, correo de contacto y horarios de atención. Son
  texto informativo; no se agrega geocodificación ni se infieren coordenadas.
- El nombre público no cambia el nombre institucional revisado ni su identidad legal.
  El correo de contacto no cambia Auth. No admite propietario, documento, CUIT, IDs,
  roles, vínculos ni nacimiento. La rectificación crítica mantiene su circuito propio.
- El propietario recibe un aviso explícito antes de guardar información pública.
  El servidor conserva revisión, operador, actor, fecha, valor anterior y nuevo.
  Auditoría privada sin lectura/escritura directa por clientes; no expuesta al catálogo.
- Revisión optimista y clave de operación estable: dos ediciones simultáneas sobre
  la misma revisión no se pisan; repetir el mismo envío no duplica la auditoría.
  Un fallo de red no se convierte en guardado local. El formulario conserva el
  envío para reintentar o permite consultar de nuevo el estado del servidor.
- El catálogo anónimo conserva visibilidad, paginación y cálculo vivo de cupo.
  Añade sólo campos públicos al resultado, sin reescribir snapshots históricos.
  La ficha sólo aparece mientras haya ofertas publicadas y visibles; un borrador
  no la publica. Guardar datos de contacto no publica ofertas ni modifica cupos.
- Ubicación pública no vacía prevalece sobre ubicación por oferta; campos de
  ubicación vacíos mantienen la ubicación ya publicada. Los contactos vacíos se
  eliminan de la presentación actual. El formulario lo informa.
- Android/web antiguos pueden leer la misma versión de catálogo ignorando campos
  opcionales. El cliente nuevo también acepta el catálogo anterior sin contactos.
- Entrada en Incorporación institucional, dentro de cada institución del propietario:
  «Editar perfil público». Cerrada por defecto: `ATENA_INSTITUTION_PROFILE_READY=false`.
  La futura activación requiere migración y autorización de distribución separadas.

## Ciclo de inscripciones y compatibilidad

Se reutiliza `c5a2987`: pendientes, confirmar/rechazar, cancelar pendientes, historial
persistente, baja auditada y disponibilidad efectiva. Las decisiones se ejecutan por
RPC con autoridad de institución/área/operador; alumnos/familias sólo leen sus perfiles
vigentes. La baja conserva confirmación original y motivo y libera grupo/actividad
atómicamente una sola vez. Los reintentos y las carreras se prueban localmente.

Defecto de compatibilidad corregido: el lector del historial de bajas dependía del
flag de nuevas acciones. Ahora reconoce y consulta el historial incluso con acciones
OFF. Nunca habilita por eso el RPC de baja ni elimina las verificaciones RLS/sesión.

**La candidata 20261016000000 ahora deja el RPC de baja SIN EXECUTE para clientes.**
Así aplicar la estructura no permite introducir el nuevo estado, ni invocando el RPC
fuera de la pantalla. Este cambio sólo afecta una migración aún no aplicada remotamente.
El ensayo local comprueba el bloqueo y habilita EXECUTE exclusivamente en su clon
para comprobar el comportamiento existente. No hay un segundo mecanismo de baja.

### Orden y condiciones de activación (no ejecutado)

1. Inventariar versiones/hash de todos los clientes del piloto y verificar las
   migraciones remotas instaladas contra las dependencias. Conservar respaldo y
   referencia de filas, RLS, funciones, grants y escenarios reservados.
2. Autorizar y aplicar `20261016000000_enrollment_withdrawal.sql`; comprobar
   `has_function_privilege('authenticated','public.atena_enrollment_withdraw(uuid,text)','execute') = false`.
   Ninguna solicitud previa debe cambiar. No habilitar aún clientes escritores.
3. Autorizar y aplicar `20261016010000_identity_rectification.sql`; requiere alta
   institucional/familiar, sesiones y catálogo revisados; su comprobación de cuerpos
   SQL falla sin cambios parciales si hay divergencia. No designa revisores.
4. Autorizar y aplicar `20261016020000_institution_public_profile.sql`; requiere
   alta institucional, catálogo/cupos y guardas de sesión. Contrastar especialmente
   `atena_catalog_read` instalado para no reemplazar cambios remotos desconocidos.
   No hace backfill ni toca tablas Auth, identidades, vínculos o publicaciones previas.
5. Autorizar distribución privada/deployment de lectores compatibles. Verificar
   lectura de `withdrawn_by_institution` y su historial aun con acciones OFF.
   Reemplazar todos los APK incompatibles y cerrar pestañas/cachés de versiones viejas.
   La condición es evidencia de sustitución de cada cliente, no una suposición.
6. Autorizar la campaña JWT ficticia separada y, sólo con lectores compatibles,
   la activación administrativa exacta:
   `GRANT EXECUTE ON FUNCTION public.atena_enrollment_withdraw(uuid,text) TO authenticated;`
   Después validar aislamiento, motivo, idempotencia, confirmación concurrente y cupo.
7. Autorizar build/distribución con `ATENA_ESSENTIAL_OPERATIONS_READY=true` y/o
   `ATENA_INSTITUTION_PROFILE_READY=true` exclusivamente después de validar cada backend.
   El constructor de evaluación de este bloque mantiene ambas acciones OFF.

La candidata actual incorpora negociación de contrato de solicitudes. Al conceder
EXECUTE para bajas, lecturas y mutaciones incompatibles fallan explícitamente en el
servidor con PT426. El cliente actual declara contrato 2; versiones anteriores no lo
declaran. No es atestación del binario ni autoridad de identidad: RLS y permisos
siguen siendo obligatorios aunque alguien manipule el encabezado. Después de una
baja, retirar EXECUTE no vuelve a habilitar lectores antiguos. Ver plan del 19/10.

Ante incidente: revocar EXECUTE para bloquear nuevas bajas, conservar todos los eventos
ya creados y los lectores compatibles. Quitar el flag o volver a un cliente antiguo NO
revierte estados existentes. No borrar auditorías ni restaurar sobre el piloto. Para
contacto incorrecto, corregir con una nueva revisión autorizada; historial permanece.

### Campaña JWT futura requerida

Escenario ficticio separado: propietario A, operador sin propiedad A, propietario B,
solicitante autorizado y revisor independiente. Verificar edición A, rechazo B/operador,
cuenta revocada y respuesta tardía; publicación/lectura anónima de contacto; retiro;
no exposición de auditoría; baja por operador con requests.decide; rechazo familiar;
inscripción previa preservada; competencia por última vacante; rectificación revisada
sin transición de menor a adulto. No usar reservas de teléfonos ni usuarios reales.

## Recorridos cotidianos y autonomía

| Actor | Operaciones existentes | Límite real |
|---|---|---|
| Propietario institucional | Alta revisada, áreas, invitación/revocación de operadores, ofertas, cupos y turnos; ficha pública preparada | Necesita identidad aprobada y permisos vigentes; ficha nueva pendiente de migración |
| Operador autorizado | Catálogo por área, pendientes/decisiones, inscripciones e historial | Capacidades limitadas; baja nueva bloqueada hasta compatibilidad/activación |
| Alumno/responsable | Acceso, perfiles autorizados, búsqueda pública, solicitudes, cancelar pendientes, decisiones, confirmaciones e historial | Edad/turno se filtran por texto publicado, no acreditan identidad ni habilitan menores |
| Revisor institucional/familiar | Colas y decisiones desde las pantallas existentes, sin autoaprobación | Cero revisores activos según última lectura; titularidad y dos autorizaciones independientes pendientes |

El buscador remoto ya no sugiere publicar en el mismo dispositivo cuando no encuentra
resultados. No se mezclan fuentes locales con éxitos remotos. Mantiene filtros existentes
por actividad, ubicación, edad, horario y disponibilidad. No se rediseña la búsqueda.

Soporte: conservar referencia de solicitud/operación, entorno y resultado sanitizado,
consultar el estado del servidor antes de repetir. No pedir contraseñas ni tokens. En
contacto público, un reintento conserva la misma operación; una recarga consulta la
última revisión. Conflicto de versión requiere recargar antes de nueva edición.

Respaldo/restauración reutiliza las herramientas existentes: incluye automáticamente
las tablas nuevas y sus políticas, funciones, grants, índices y auditorías. Ensayo
cifrado sólo con PostgreSQL local y objeto Storage ficticio separado. No equivale a
recuperación integral del servicio Supabase Auth/Storage alojado. No se hicieron copias
remotas, purgas, cambios de retención ni restauraciones sobre el piloto.

## Validación de esta unidad

- Flutter: 151 casos focalizados aprobados. La ejecución conjunta dejó 150 PASS y
  un fallo en el fixture de presentación pública (sin ofertas); corregido el fixture,
  se repitieron sus nueve casos y todos pasaron. No se relajó ninguna expectativa.
  Incluye incorporación institucional/familiar, rectificación, bajas, publicación,
  búsqueda, contexto de sesión, navegación y cancelación de solicitudes.
- PostgreSQL local: 59 controles de operaciones esenciales + 35 de ficha pública,
  todos PASS. Incluye carreras de edición, autorización, auditoría y privacidad.
  Se usan roles/claims ficticios locales; no equivalen a una prueba JWT remota.
- Restauración aislada cifrada: 13 verificaciones PASS sobre 49 tablas, incluyendo
  integridad, RLS, permisos y objeto Storage ficticio separado. No se restauró el piloto.
- Análisis estático: 76 avisos históricos, sin avisos nuevos; salida 1 por ese baseline.
- Compilaciones: Android release PASS (95,2 MB) y web JavaScript PASS. Advertencias
  preexistentes de compatibilidad Wasm en dependencias; no se generó un build Wasm.
  Identidad Android `org.atena.evaluation.multiuser`, nombre «Atena Multiusuario»,
  proyecto piloto verificado. Recuperación por correo y nuevas acciones permanecen OFF.
  Artefactos privados en `build/evaluation/atena-v1-piloto-evaluacion.apk` y
  `build/evaluation/atena-v1-piloto-web.zip`; hashes verificados contra el manifiesto.
  Escaneo de patrones de secretos privilegiados en APK/web: sin coincidencias.
  No se distribuyeron ni desplegaron.
- `git diff --check` y `git diff --cached --check`: PASS.
- Revisión de Git: 17 archivos de esta unidad; sin patrones de secretos detectados.
  Los 312 archivos protegidos conservan SHA-256; diagnóstico SQL ajeno excluido.

No se ejecutó la suite general ni se repitieron campañas JWT remotas ya aprobadas.
Los ensayos SQL se ejecutaron con `tool/test_essential_operations.py` y
`tool/test_institution_public_profile.py`, clonando sólo bases locales desechables.
La recuperación utiliza `tool/rehearse_local_recovery.py --encrypted-roundtrip`.
El constructor existente `tool/build_pilot_evaluation.py` fija Flutter 3.38.3 y
comprueba que `pubspec.lock` no cambie. El manifiesto de evaluación registra fuentes,
configuración pública, herramientas y hashes; no promete binarios idénticos entre equipos.

## Pendientes externos para datos reales

- Autorización de las tres candidatas, campaña JWT y activación compatible.
- Cuenta administrativa personal verificada y permisos de ambos revisores autorizados.
- Entrega de correo para participantes reales y recuperación legítima probada; dominio
  no es requisito de las operaciones locales, pero SMTP/Resend siguen pospuestos.
- Responsables de soporte y verificación, privacidad/menores, conservación y recuperación
  integral aprobados. No se declara conformidad legal ni producción lista.
- Distribución y evaluación integral posteriores; pruebas físicas/manuales pospuestas.

Siguiente acción del propietario: acreditar su cuenta de revisor y decidir la activación
remota de las candidatas y de la campaña ficticia. No hace falta contratar dominio ni
rehacer arquitectura para continuar esas decisiones.
