# Contexto remoto autorizado — piloto

## Estado al 6 de octubre de 2026

Aplicada una vez al proyecto piloto `eaegvxxxkvhdukbkydvy`:

`supabase/candidates/20261006000000_authenticated_context.sql`

SHA-256 del archivo probado y aplicado:
`c2578074668cc34cf54b3d010a0a17d4c6c60c61b0424f4b2dbcb78bf19f3b56`.

La versión quedó registrada en `supabase_migrations.schema_migrations`.
No reaplicar el candidato. No se modificaron los datos de las tablas existentes,
usuarios Auth, funciones anteriores, RLS, grants existentes ni capacidades.
El enforcement comercial continúa desactivado.

## Contrato

`public.atena_authenticated_context()` no recibe argumentos. Deriva la identidad
exclusivamente de `auth.uid()`. Requiere una identidad autenticada y devuelve:

- `auth_user_id`: identidad del propio solicitante de la consulta.
- `applicant_profiles`: sólo `profile_id` de sus vínculos solicitantes activos.
- `institutional_contexts`: institución, área, operador y sus identificadores
  públicos; nombres de institución/área; capacidades operativas asignadas.

El contexto institucional exige operador, vínculo verificado, asignación y área
activos; vínculo no revocado; propietario coherente cuando es un operador dueño;
y alcance de catálogo previamente autorizado. Sólo devuelve la intersección con
`catalog.publish`, `requests.read` y `requests.decide`. No devuelve registros de
verificación, cuentas locales, correos, notas, credenciales ni perfiles ajenos.

Una identidad sin vinculaciones recibe listas vacías. No se elige un perfil
arbitrariamente. No hay acceso anónimo a la función. Las tablas privadas siguen
inaccesibles para el cliente. La función usa `SECURITY DEFINER`, `STABLE` y
`search_path` vacío; las referencias de esquema son explícitas.

La respuesta sirve para presentar opciones autorizadas, no como permiso
persistente: cada operación de publicación/solicitud/decisión sigue revalidando
identidad, asignación y capacidades en los RPC existentes.

## Evidencia y límite

`tool/test_authenticated_context.py` ejecutó 26 comprobaciones PASS en PostgreSQL
local descartable. Incluyen aislamiento A/B, solicitante sin privilegios
institucionales, identidad sin vínculos, denegación anónima, argumentos arbitrarios,
propietario contradictorio, revocaciones, operador independiente del dueño,
ausencia de escrituras del cliente y preservación de RLS/permisos anteriores.

El runner acepta únicamente localhost y una base vacía llamada
`atena_disposable_context`, con usuario `atena_test`. No usar sus fixtures contra
Supabase. Simula claims únicamente para probar SQL local, no autenticación JWT.

Tras aplicar la migración se contrastaron la definición efectiva y los grants
remotos con lo probado; se comprobaron fingerprints de todas las tablas Atena
existentes y de los identificadores/fechas de actualización de Auth, sin leer
contraseñas. Los datos y los objetos previos permanecieron iguales.

## Conexión Flutter con Auth real

El 6/7 de octubre se restablecieron exclusivamente las contraseñas de las tres
identidades ficticias autorizadas, sin cambiar sus UUID, correos, metadata,
asignaciones ni roles. Las contraseñas se generaron y mantuvieron sólo en memoria.
No se incluyen claves administrativas, contraseñas ni tokens en código/build/Git.

GoTrue autenticó a las tres identidades con contraseña; `/auth/v1/user` aceptó sus
JWT reales. El contexto confirmó A → institución A; B → institución B y su propio
perfil solicitante; C → su propio perfil sin autoridad institucional. Se rechazaron
el acceso anónimo, JWT inválido y argumentos para elegir otra identidad.

`ATENA_MULTIUSER=true` selecciona explícitamente el backend compartido:
- Los ingresos habituales autentican con Supabase Auth.
- Cuenta muestra sólo los perfiles y áreas descubiertos por el RPC autorizado.
- El buscador/perfil público usa el catálogo remoto anónimo.
- La intención de solicitar se conserva al ingresar y elegir el perfil verificado.
- Solicitudes de alumno/institución usan los RPC remotos y RLS; la confirmación
  cambia el cupo atómicamente en PostgreSQL. No hay confirmación optimista local.
- Los reintentos conservan la clave de operación y el servidor decide idempotencia.
- Cerrar sesión cierra la sesión Supabase de este dispositivo y elimina la pila
  autenticada. No crea ni reutiliza sesiones de cuenta/perfil locales.
- El arranque remoto no importa ni borra datos locales. El modo local sigue siendo
  el valor predeterminado de compilación, con su recorrido anterior intacto.

## Límite deliberado de esta evaluación

Sólo identidades ficticias y áreas previamente habilitadas. No hay alta remota de
usuarios/grupos/cupos desde los formularios locales, migración automática ni
vinculación por correo. El panel de catálogo permite publicar de nuevo la ficha
remota existente; no provisiona recursos nuevos ni importa grupos locales.
Registro/recuperación local no se ofrecen en este modo. Otros módulos locales
(calendario, documentos, educación, etc.) no se presentan como sincronizados.

La disponibilidad se consulta al abrir/actualizar y tras decidir; no se implementó
Realtime. En el otro dispositivo se debe pulsar **Actualizar**. La sesión remota
persiste según Supabase Auth; esto no equivale a revocación global inmediata de
JWT emitidos. El enforcement comercial sigue OFF.

Para Android se agregó permiso INTERNET en release y la opción de paquete
independiente `ATENA_ANDROID_MULTIUSER=1` (`org.atena.evaluation.multiuser`, nombre
“Atena Multiusuario”). No reemplaza Atena Demo ni su almacenamiento. Continúa la
firma de evaluación existente: no es una entrega de producción/Play Store.

## Reproducción y validación

- `test/multiuser_session_test.dart`: contratos de contexto, aislamiento,
  búsqueda remota, rechazo de perfiles ajenos, errores sin fallback y reintentos.
- `test/multiuser_remote_live_test.dart`: prueba opt-in de widgets reales contra
  Supabase con tres clientes/Auth independientes. El launcher seguro inyecta
  credenciales sólo en el entorno del proceso, nunca en argumentos/archivos.
  No sustituye `auth.uid()` ni usa autoridad administrativa para operar Flutter.
- El test vivo necesita un recurso ficticio habilitado, una vacante disponible y
  ningún ingreso confirmado previo para el perfil solicitante de la campaña.
  No se ejecuta automáticamente en la suite offline ni se repite sobre datos reales.

La configuración de build contiene únicamente entorno staging, URL del proyecto,
clave **publishable** y `ATENA_MULTIUSER=true`; se suministra externamente mediante
`--dart-define-from-file`. No incluir secretos administrativos ni credenciales en
ese archivo. APK de evaluación: `build/atena-v1-multiusuario-evaluacion.apk`.

Resultados verificados:
- 413 tests Flutter offline PASS (402 previos + 11 nuevos), 0 skipped.
- 1 test vivo adicional de widgets con Supabase Auth/JWT reales PASS: login A,
  publicación, buscador/perfil anónimo B, login B, selección autorizada, solicitud,
  rechazo directo de perfil/autoridad ajenos por los RPC, aislamiento respecto de
  C, confirmación desde A, lectura confirmada desde B y disponibilidad 0 en ambas
  sesiones. Repetir la decisión no incrementó nuevamente la ocupación.
- Logout y reconstrucción sin perfil remoto previo; marcador local conservado.
- 76 avisos estáticos históricos, 0 nuevos (analyze devuelve 1 por la línea base).
- Lectura administrativa final: capacidad 2, ocupación 2, dos confirmaciones;
  la confirmación anterior de C permanece. Siete tablas piloto protegidas sin
  diferencias; enforcement OFF.
- Build web JavaScript y APK release: PASS, ambos configurados para el piloto.
  Continúan advertencias históricas del dry run Wasm y synthetic-package.
  APK comprobado: paquete org.atena.evaluation.multiuser, permiso INTERNET,
  URL y clave publishable correctas en las tres arquitecturas compiladas.
- `git diff --check`: PASS.

Los fallos intermedios fueron del harness de widgets (espera de I/O en reloj
simulado, selector de tarjeta y timers de conexiones HTTP al cerrar). Se corrigió
el harness sin relajar expectativas. Se eliminaron únicamente solicitudes
confirmadas derivadas de ejecuciones fallidas y su ocupación, con transacciones
acotadas a IDs verificados y comprobación de los demás datos intactos.

La prueba física aún no se realizó. Para repetir desde dos teléfonos se necesitan
credenciales ficticias que el responsable pueda introducir de forma segura y
preparar una nueva vacante/escenario de campaña autorizado: el escenario validado
quedó confirmado y lleno. Las contraseñas temporales no se conservan ni se incluyen
en el APK. No se borró la prueba exitosa para dejar artificialmente el cupo libre.
No se realizó deployment. La modificación previa del diagnóstico SQL y los cuatro
elementos históricos quedan fuera de esta unidad.
