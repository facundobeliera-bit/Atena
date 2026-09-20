# Piloto remoto de Atena

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
credenciales históricas de Atena. P1-B y P1-D siguen pendientes. Staging no se
modificó.
