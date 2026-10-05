# Piloto remoto de Atena

## Registro experimental de identidades verificadas (aplicado, validación bloqueada)

`20260920000001_atena_pilot_verified_links.sql` se aplicó al proyecto piloto
el 20 de septiembre de 2026. Añade un circuito separado para identidades y operaciones
ficticias. No cambia el ingreso habitual, las cinco tablas piloto previas, sus
políticas ni la función `atena_pilot_record_note`. Los IDs locales admitidos en
este circuito empiezan con `pilot-`; no se incorporan cuentas históricas.

El vínculo no puede crearse desde Flutter. Un responsable administrativo debe:

1. Verificar por separado a la persona y su facultad de representar la cuenta
   ficticia, sin aceptar como prueba un email, nombre o ID introducido en el
   cliente. Para el ensayo se usa una orden de prueba con referencia única.
2. Comprobar el `auth.users.id` autenticado, la institución y el operador
   aprovisionado. Cada operador tiene su propio usuario Auth. El estado de
   propietario se obtiene del registro de operador, no de una etiqueta enviada
   por el cliente.
3. Registrar el vínculo con `service_role` **sólo en un entorno administrativo**,
   incluyendo `verification_ref` y `verified_by`. La clave administrativa no
   debe entrar en Flutter, el build web, Git ni registros de pruebas. La FK
   compuesta impide asociar al operador de otra identidad Auth; índices únicos
   impiden dos identidades activas para la misma cuenta local u operador.
4. Revocar el vínculo estableciendo `active=false` y `revoked_at`. El circuito
   verificado comprueba el vínculo y la asignación activa en cada operación;
   los datos de auditoría permanecen almacenados, pero dejan de ser legibles
   para el vínculo revocado.

La tabla de vínculos permite al usuario leer sólo su propio registro y no
concede escrituras al cliente. La tabla de operaciones verificadas permite
lectura según RLS y escritura únicamente por la función
`atena_pilot_record_verified_note`, que toma la identidad de `auth.uid()`.
La prueba opcional `-TestVerifiedLinks` del smoke test anterior crea sólo
identidades ficticias y comprueba ausencia de vínculo, contradicciones,
suplantación, aislamiento por institución y área y revocación con un token ya
emitido. En la ejecución remota, las 29 comprobaciones anteriores y las
primeras del vínculo nuevo pasaron. La creación administrativa del primer
vínculo falló con HTTP 400 / `23514` (`Identidad piloto contradictoria`),
aunque las lecturas administrativas mostraron operador y propietario
coherentes. No se alcanzaron las pruebas posteriores de aislamiento y
revocación del circuito verificado. No interpretar esta etapa como validada.

El registro de `verification_ref` documenta la decisión administrativa; no
verifica por sí mismo una cuenta histórica. Diseñar esa comprobación real,
revocar sesiones Auth y migrar módulos habituales son etapas posteriores.

Las migraciones `20260919000000_atena_pilot_operational_context.sql`,
`20260919000001_atena_pilot_admin_provisioning.sql`,
`20260919000002_atena_pilot_self_assignments.sql` y
`20260920000000_atena_pilot_area_assignment_read.sql` se aplicaron al proyecto
de pruebas `eaegvxxxkvhdukbkydvy` el 19 y 20 de septiembre de 2026. No
incluyen datos históricos de Atena. El segundo archivo concede `select` e `insert`
exclusivamente al rol administrativo `service_role` para aprovisionar datos
ficticios; los clientes siguen sin escritura directa.

La tercera migración habilita `select` de operadores y asignaciones sólo para
el operador activo autenticado y sus asignaciones activas. No concede escrituras.
La cuarta restringe la lectura de áreas a las asignadas con `pilot.read`,
usando la misma comprobación de capacidad que protege las notas. Ninguna de
estas migraciones altera la estructura de las tablas ni permisos administrativos.

## Alcance aplicado

Las migraciones crean cinco tablas aisladas con prefijo `atena_pilot_`:
instituciones, áreas, operadores, asignaciones y operaciones de prueba. Sólo
permiten leer instituciones/áreas propias y notas de áreas autorizadas.
La única escritura desde el cliente sería la función
`atena_pilot_record_note`, que exige usuario Supabase autenticado, operador
vinculado a ese usuario, asignación activa y capacidad `pilot.write`.
`anon` no recibe acceso. Los clientes no pueden crear operadores ni modificar
asignaciones. Ninguna tabla existente se altera y no hay migración de datos.

La vinculación entre `auth.users.id` y los IDs locales de Atena debe hacerse
por un administrador después de verificar la identidad real. El nombre visible
de un operador, `cuentaId` local o `workProfileId` nunca demuestra esa relación.
La operación de prueba registra ambos IDs: operador y usuario autenticado.
El propietario tampoco recibe una excepción automática de capacidades.

## Configuración optativa del cliente

El arranque sigue siendo local si `ATENA_REMOTE_ENV` no está definido.
Una compilación de piloto requiere `ATENA_REMOTE_ENV=staging`, la URL pública
en `ATENA_SUPABASE_URL` y una clave `sb_publishable_...` en
`ATENA_SUPABASE_PUBLISHABLE_KEY`, suministradas como `--dart-define` durante
el build. Nunca se suministra una clave secret o service_role al cliente.
Producción requiere otra URL y no puede apuntar al proyecto de staging.
La clave publishable estará presente en la aplicación compilada: RLS, no su
secreto, protege los datos.

La integración está deliberadamente aislada. El repositorio remoto de notas
de prueba no sustituye solicitudes, cupos, documentos, cuentas ni sesiones
locales. En un build configurado para el piloto aparece «Abrir piloto remoto»
en la portada. Esa pantalla inicia sesión en Supabase con una cuenta ficticia,
obtiene automáticamente su operador y asignaciones, lista sólo las instituciones
y áreas asignadas, y permite registrar y consultar notas de prueba. La función
remota vuelve a comprobar que el operador pertenezca al usuario autenticado y
al área; no confía en los identificadores enviados por Flutter.
El login habitual de Atena no inicia sesión en Supabase.

## Validación remota realizada

El script `../tool/supabase_pilot_smoke.ps1` probó dos usuarios, dos instituciones,
dos áreas y dos asignaciones ficticias. Sus 29 comprobaciones remotas pasaron
después de las cuatro migraciones. Cada usuario pudo autenticarse, leer sus
datos, registrar una nota y recuperarla desde una segunda sesión. Ambos fueron
bloqueados al leer o escribir en la institución ajena, al crear asignaciones y
al insertar directamente en la tabla de operaciones. Las consultas manipuladas
sin filtro y con IDs ajenos tampoco expusieron datos. El acceso anónimo fue
rechazado. Las
contraseñas y claves se usaron sólo en memoria; no se guardaron en el repositorio.
La ejecución comprobada corresponde al identificador ficticio
`14fb14c645f1`. No se probó aún la revocación dinámica de `pilot.write`.

`test/pilot_remote_live_test.dart` ejecuta además el mismo contrato mediante
`SupabaseClient` real: autenticación A/B, aislamiento, nota, recuperación desde
otra sesión, identidad automática y logout. El test se activa sólo cuando el lanzador local proporciona
las credenciales ficticias por variables de entorno. El test de pantalla
`test/pilot_remote_page_test.dart` verifica el flujo visible con un sustituto
controlado y una sesión inválida, sin llamar al backend. El build web piloto se
abrió en Chrome local. Se verificaron ingreso válido A/B, operador automático,
institución y área propias, notas remotas, escritura desde la pantalla, lectura
tras F5, logout persistente tras F5 y mensaje ante credenciales inválidas. El
test Flutter real volvió a pasar después de la última política RLS. Chrome
funcionó con un perfil local aislado; no hubo publicación ni prueba sobre la URL
de staging.

Esto valida el circuito Flutter–Supabase aislado, no la seguridad de las
credenciales históricas de Atena. P1-B y P1-D ya se cerraron para las sesiones
locales, pero aún no existe vinculación con Supabase Auth para cuentas reales.
Staging no se modificó durante aquella validación.
