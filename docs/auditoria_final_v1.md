# Atena — auditoría final V1 · 09/10/2026

Base revisada: `00b23644c14187e94966af2687c8e219fe8b1f6b`.
Alcance: estabilidad, aislamiento y persistencia de los recorridos existentes.
No incorpora módulos, diseño, dependencias, migraciones ni cambios comerciales.

## Defectos comprobados y corregidos

No se demostró un defecto crítico nuevo. Se corrigieron tres problemas altos:

1. **Pantallas privadas sobrevivían al cambio o cierre de sesión remoto.**
   `AtenaApp` no escuchaba los eventos de Supabase Auth: una ruta ya abierta
   conservaba su contenido aunque la sesión dejara de existir o cambiara de usuario.
   Dos pruebas de navegación reprodujeron el fallo antes de la corrección.
   Ahora se descarta el Navigator completo cuando termina/cambia una identidad
   autenticada. Back no reconstruye las vistas anteriores. La renovación del token
   de la misma cuenta no interrumpe la pantalla. El primer ingreso conserva la
   navegación del formulario para no perder la oferta pública pendiente.
2. **Reintento de solicitud bloqueado por el catálogo.** Antes de llamar al RPC,
   el cliente exigía reencontrar la oferta pública. Un retiro o un error del catálogo
   impedía recuperar una operación previamente aceptada por PostgreSQL.
   Dos pruebas reprodujeron el fallo. Se envía la misma clave de operación al RPC,
   que resuelve idempotencia y sigue validando identidad, publicación y capacidad
   para solicitudes nuevas. No se omiten controles del servidor.
3. **Respuesta de solicitud aceptada después de cambiar de identidad.**
   La creación no comparaba al finalizar la identidad original con la vigente,
   ni comprobaba el propietario de la respuesta. La regresión demuestra ambos
   casos. Ahora se rechaza la confirmación visual en una sesión diferente y una
   respuesta cuyo propietario no corresponda. No se revierte una operación que el
   servidor pueda haber confirmado: su dueño debe consultarla/reintentar con la
   misma clave. No existe escritura local sustitutiva.

Archivos productivos: `lib/main.dart` y
`lib/services/remote/multiuser_session.dart`.
Pruebas: `test/multiuser_session_test.dart` y
`test/multiuser_navigation_security_test.dart`.

## Evidencia y validación

- Suite Flutter: **448 PASS**, **0 omitidas** (439 previas + 9 regresiones).
- Pruebas nuevas: retiro de oferta, catálogo caído, cambio de identidad durante
  creación, respuesta de otro propietario, logout, cambio de usuario, renovación
  de la misma sesión, sesión expirada irrecuperable y primer login con oferta pendiente.
- PostgreSQL local: **175 PASS** (calendario/comunicaciones, educación y documentos)
  y **48 PASS** adicionales de catálogo/solicitudes/capacidad.
  Incluyen dos conexiones concurrentes por la última vacante, un solo ganador,
  reintentos terminales sin consumo doble, rollback y capacidad compartida.
- Supabase piloto: **42 PASS** con Auth/JWT reales y operaciones de lectura.
  Incluyen perfiles ajenos, institución ajena, acceso anónimo, tablas privadas,
  escenario físico reservado sin consumir y enforcement comercial OFF.
- Comparación remota/local: **43 funciones coinciden**, incluidos cuerpo,
  argumentos, SECURITY DEFINER y configuración. Sin funciones faltantes/adicionales.
  No se aplicaron migraciones, permisos ni escrituras de datos de negocio remotos.
- El E2E de escritura multiusuario del sprint anterior sigue siendo evidencia
  previa; no se repitió su limpieza remota en esta auditoría, que prohíbe borrar datos.
- `flutter analyze`: **76 avisos históricos, 0 nuevos**. Devuelve código 1 por esos
  avisos; no se presenta como análisis sin advertencias. No se detectó en esos
  avisos un defecto funcional o de seguridad que exigiera modificar otros módulos.
- Builds web JavaScript y APK multiusuario: **PASS** sobre el código final.
  Web conserva los avisos de compatibilidad del ensayo WASM; no se valida WASM.
- `git diff --check`: limpio. Los archivos históricos y el diagnóstico SQL local
  preexistente quedan fuera del commit; sus hashes permanecen intactos.

## Persistencia y seguridad

El modo multiusuario utiliza Supabase para catálogo, solicitudes, decisiones,
calendario/comunicaciones, seis módulos educativos y documentos. Los adaptadores
revisados no convierten errores de red en guardados locales. La configuración y
sesión Auth persistidas en el dispositivo no son datos compartidos de negocio.
El modo local conserva sus servicios, credenciales y sesiones independientes,
con cobertura de la suite completa. No se migraron datos históricos.

PostgreSQL sigue siendo la autoridad para capacidades, vínculos y cupos.
Los documentos sólo se abren mediante RPC autorizado, sin URL pública; los
borradores educativos y la auditoría privada no se publican. La proyección pública
usa su lista permitida de campos, sin devolver credenciales ni identidad operativa.

Se escanearon archivos versionados, blobs alcanzables del historial, web y entradas
extraídas del APK por patrones de claves privadas/privilegiadas y por coincidencia
con contraseñas ficticias vigentes mantenidas sólo en memoria. Sin coincidencias
secretas detectadas. La clave pública publicable del piloto es deliberada.
Esta comprobación no equivale a una garantía absoluta ni a una auditoría externa.

## Pendientes y límites

- No se ejecutó la prueba física. Falta comprobar instalación, ciclo de vida,
  reconexión y lectura entre dos teléfonos reales.
- El piloto requiere identidades, áreas, ofertas y recursos remotos previamente
  habilitados. La pantalla de catálogo revisa/republica los datos habilitados;
  no convierte automáticamente grupos locales en recursos remotos ni ofrece un
  alta remota completa. No se amplió ese alcance como parte de la auditoría.
- Documentos: el vencimiento bloquea el acceso en el servidor; la purga física
  depende de una operación explícita, no de una tarea automática. El piloto limita
  archivos a 2 MiB. Las copias ya descargadas fuera de Atena no pueden revocarse.
- Logout usa el alcance local de Supabase Auth. El descarte visual no constituye
  una revocación instantánea de todos los JWT emitidos en otros dispositivos.
  Los permisos y vínculos se revalidan en el servidor, pero no se declara resuelta
  una política global de revocación/retención para producción.
- Sin realtime ni cola offline remota: es necesario actualizar/reintentar. Si se
  pierde una respuesta, consultar el estado y conservar el intento; no interpretar
  el error como prueba de que la operación no llegó al servidor.
- APK de evaluación firmado con la configuración de pruebas existente. No es una
  publicación de producción. Sin deployment ni datos personales reales.

## Prueba manual mínima

1. Instalar `build/atena-v1-cierre-tecnico-evaluacion.apk` en dos dispositivos,
   usando las cuentas ficticias institucional y alumno del escenario reservado.
2. Alumno solicita la oferta TEST; institución actualiza y confirma; alumno
   actualiza. Ambos deben observar el mismo estado y disponibilidad.
3. Interrumpir/restaurar red y repetir un envío sin duplicarlo; actualizar para
   comprobar el resultado confirmado por el servidor.
4. Abrir calendario, un registro educativo visible y un documento autorizado.
   Otra identidad no debe poder acceder a ellos.
5. Cerrar sesión con una pantalla privada abierta, usar Back y reiniciar: no deben
   reaparecer datos de la cuenta anterior. Repetir cambiando de cuenta.

Conclusión: correcciones locales comprobadas para continuar evaluación manual;
no se declara aprobada la prueba física ni disponibilidad para producción.
