# Operaciones esenciales del piloto — candidatas locales (2026-10-16)

## Estado y alcance

Baja institucional de inscripciones confirmadas y rectificación revisada de los
campos de identidad existentes. Implementación y pruebas locales; **no activadas
en Supabase**. No hay migración remota, usuarios nuevos, cambios de permisos remotos,
correo, deployment ni prueba manual/física en este bloque.

Las acciones nuevas están cerradas por defecto mediante
`ATENA_ESSENTIAL_OPERATIONS_READY=false`. El servidor sigue siendo la autoridad:
el flag sólo controla disponibilidad en la interfaz, nunca concede permisos.
El APK de evaluación conserva el flag desactivado. El modo local existente no
se convierte en remoto ni adquiere un segundo contrato de identidad.

## Baja confirmada

- Acción en Solicitudes institucionales, sólo con `requests.decide` para la
  institución/área; servidor obtiene al operador desde `auth.uid()` y vuelve a
  validar sesión, identidad vinculada, propietario cuando corresponda, área y
  asignación activas. Un alumno/familiar no puede darse de baja por este RPC.
- Estado nuevo `withdrawn_by_institution`. No se reutilizan las cancelaciones de
  pendientes. No se borra la solicitud, ni se permite reconfirmar esa misma fila.
  Una solicitud nueva posterior puede seguir el recorrido normal.
- Motivo obligatorio (8–300 caracteres), visible para los interesados autorizados;
  la pantalla indica no incluir datos sensibles. Tabla de eventos con inscripción,
  institución/área, fecha y autor original de confirmación, fecha y autor de baja.
  RLS limita su lectura a quienes pueden leer la solicitud; clientes sin permisos
  de INSERT/UPDATE/DELETE sobre esa auditoría.
- Bloqueo de la solicitud y de los pools de cupo ordenados, igual que confirmación.
  En cada pool: `max(ocupación almacenada, confirmaciones efectivas previas) - 1`.
  Grupo y actividad se liberan en la misma transacción. Se conserva ocupación
  histórica/importada adicional, incluso sobreocupación; no se hace clamp.
- Repetir la misma baja/motivo devuelve el evento existente sin liberar otra plaza.
  Un motivo distinto en un reintento se rechaza. Una carrera con confirmación se
  serializa por el mismo pool; una confirmación rechazada puede reintentarse.
- Si faltan los autores originales de una confirmación anómala, no se inventan:
  falla toda la operación, incluyendo la liberación. Requiere revisión separada.
- Las consultas de alumno/familia muestran la baja e historial al actualizar.
  No hay sincronización realtime ni una falsa confirmación local tras error de red.
  Las autorizaciones educativas basadas en inscripción `confirmed` no se extienden
  al nuevo estado. El historial existente no se elimina.

## Clasificación de identidad y edición

| Datos | Contrato del piloto compartido |
|---|---|
| Presentación de oferta: descripción, ubicación, horarios, requisitos y etiquetas | Editor de catálogo existente, con autorización de área y publicación explícita; no concede identidad. |
| Contacto (teléfono/correo informativo) | Los formularios locales existentes lo conservan localmente; no se anuncia sincronización de esos campos. Este bloque no crea campos remotos ni cambia el correo de Supabase Auth. |
| Nombre del perfil y nacimiento | Propuesta del titular/responsable ya autorizado, aprobación por revisor familiar existente e independiente. No hay edición directa. |
| Nombre institucional | Propuesta del propietario vigente, aprobación por revisor institucional existente e independiente. El siguiente guardado/publicación usa el nombre revisado; no reescribe publicaciones históricas automáticamente. |
| DNI/documento, CUIT, identidad Auth, IDs de perfil/operador/propietario | No se editan por este mecanismo. DNI/CUIT de formularios legacy no acreditan identidad remota. El esquema remoto de rectificación no agrega estos campos. |
| Vínculos de responsables y facultades sobre menores | Continúan exclusivamente en el circuito familiar revisado existente. No se transfieren mediante edición de nombre o fecha. |

En el modo local, el registro de perfil de alumno permite DNI, nombre/apellido,
nacimiento, correo informativo y teléfono; el área del alumno muestra la ficha.
El perfil institucional local permite nombre, CUIT, correo, teléfono y ubicación,
además de información pública. Son estructuras locales anteriores: no se migran,
no se usan como autoridad para Supabase y no se modificaron en este bloque.

La pantalla nueva «Rectificación de identidad» solicita revisión y muestra sus
resultados. Reutiliza los revisores familiares/institucionales existentes; no crea
roles, no designa revisores y no se acepta autoaprobación. El servidor conserva
valores anteriores/propuestos, motivo, solicitante, revisor, referencia y fechas.
Una propuesta pendiente no cambia el perfil. Se revalidan acceso del solicitante,
cuenta activa y valores originales al aprobar; se rechazan propuestas obsoletas.

No permite atravesar la frontera menor/mayor de 18 años modificando nacimiento,
ni al solicitar ni al aprobar. La transición legítima a mayoría de edad permanece
en el circuito familiar existente. Una corrección real que cruce esa frontera
necesita un procedimiento adicional explícitamente autorizado: no está habilitada.
La acreditación de identidad sigue siendo revisión administrativa documentada;
no se presenta como verificación automática contra un registro oficial.

## Migraciones pendientes y activación propuesta

1. `supabase/candidates/20261016000000_enrollment_withdrawal.sql`
2. `supabase/candidates/20261016010000_identity_rectification.sql`

Dependen de catálogo/solicitudes, sesiones, publicación editable, alta institucional
`20261010000000` y familiar `20261013000000`. La segunda comprueba la forma de las
funciones de catálogo antes de adaptarlas al nombre revisado; si no coincide, su
transacción falla sin cambios parciales. No son scripts para reaplicar repetidamente.

**Se requiere autorización expresa para aplicarlas al piloto**. Antes: cotejar
historial/esquema remoto y SQL exacto. Después: verificar funciones, RLS y grants,
conteos/hash históricos y ensayar con JWT ficticios autorizados en escenario
separado. No usar las reservas de teléfonos. La autorización también debe definir
qué revisores existentes atenderán las solicitudes, sin conceder roles por defecto.

Antes de habilitar la primera baja, actualizar todos los clientes del piloto: los
clientes antiguos no reconocen el nuevo estado y pueden rechazar la lectura de
solicitudes. El cliente nuevo reconoce ese estado aun con las acciones OFF, lo
que permite distribuir compatibilidad primero. No ejecutar bajas mientras
convivan clientes incompatibles.

Sólo tras esos controles se podrá compilar un cliente con
`--dart-define=ATENA_ESSENTIAL_OPERATIONS_READY=true` junto con la configuración
piloto habitual (Android usa `ATENA_ANDROID_MULTIUSER=1`). El constructor actual
mantiene el flag OFF por defecto. La distribución/deployment requiere autorización
separada. No se propone revertir eliminando auditorías: ante incidente, deshabilitar
las acciones y preparar corrección compatible conservando filas e historial.

## Reproducción automatizada

`tool/test_essential_operations.py --psql <psql-local> --port 55441 --base-db <atena_disposable_baseline>`
clona una base desechable local existente, usa sólo `127.0.0.1` y cuentas
`example.invalid`. Nunca conecta al piloto ni modifica la base fuente. La base
debe contener las migraciones anteriores aplicadas. Sus roles/claims son fixtures
SQL locales; **no equivalen a una campaña JWT real**.

Resultados de esta unidad:

- 58 comprobaciones PostgreSQL locales: conservación de filas anteriores por cada
  migración; autorización/aislamiento; baja, idempotencia y auditoría; ocupación
  importada y subdeclarada; grupo/actividad; conexiones simultáneas; rollback ante
  error de auditoría; rectificación, autoaprobación, rechazo, revocación y conflicto.
- 82 pruebas Flutter relacionadas PASS (81 de regresión + 1 de pantalla estrecha), incluidas 18 nuevas; adaptadores y widgets
  contra HTTP local controlado. No escrituras locales aparentando éxito remoto.
- Análisis: 76 diagnósticos históricos, 0 nuevos (salida 1 por la línea base).
- Android release y web JavaScript: PASS. `git diff --check`: PASS.
  APK: `build/evaluation/atena-v1-piloto-evaluacion.apk`, con acciones nuevas OFF.
  El diagnóstico opcional Wasm conserva avisos anteriores; el build aprobado es JavaScript.
- Se conservan los 312 archivos protegidos y el cambio previo ajeno en
  `supabase/diagnostics/pilot_link_predicate_readonly.sql`.

## Pendientes reales

Estas dos operaciones aún requieren activación remota y pruebas JWT específicas.
No sustituyen los requisitos operativos ya registrados: revisores designados,
correo/recuperación legítima validada, soporte, privacidad/menores, conservación y
recuperación integral aprobadas antes de datos reales. La prueba física continúa
pospuesta. No se declara producción lista ni se repiten auditorías generales.
