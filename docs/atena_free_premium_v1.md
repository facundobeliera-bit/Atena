# Atena V1 — Política comercial Free / Premium

Fecha: 2026-10-05. Unidad local de evaluación, sin pagos ni cambios remotos.

## A. Estado inicial comprobado

Rama `fix/buscar-instituciones-alumno`; HEAD `fb1388ccc14741e6e10cd12d36eca5712db59faf`.
Se ejecutó nuevamente la suite inicial: **354 PASS**, sin fallos ni omitidos.
El directorio ya contenía la consolidación, el buscador público, cambios Android y trabajo del piloto sin confirmar. El staging estaba vacío. Esos cambios no se descartaron ni se consideraron parte nueva de esta unidad.
Se guardaron fuera del repositorio la lista de estado y huellas de 399 archivos para distinguir el trabajo previo del delta actual.

## B–C. Modelo y política reutilizados

Se reutilizan `Institucion.tipoPlan`, `estadoPlan`, `planInicio`, `planFin` y `planConfig`. No hay nueva tabla, otro registro de suscripciones ni migración masiva.
La política vive en `lib/services/plan_habilitacion_service.dart`:

- `planComercial`: clasifica únicamente valores explícitos Free/Premium, normalizando espacios exteriores y mayúsculas. Los códigos históricos por módulo, pruebas y valores desconocidos quedan sin clasificar.
- `puedeRecibirNuevasSolicitudes`: decisión comercial adicional, separada del guard operativo existente.
- `puedeRecibirPorId`: consulta el registro de `InstitucionService` que guarda la pantalla de planes. No utiliza como autoridad comercial la caché del buscador, el snapshot publicado ni parámetros de navegación.

Con enforcement ON se requiere Premium explícito y estado operativo `activo`. Estados vencido, suspendido, enPrueba, sinPlan o sin institución canónica no otorgan el permiso. La normalización operativa histórica no se modificó.

## D–E. Configuración y estado de entrega

Única fuente: constante de compilación `ATENA_COMMERCIAL_ENFORCEMENT`, con valor por defecto **false**.
No existe interruptor de usuario, contraseña especial, excepción por documento, preferencia persistida ni parámetro de URL.

El build web y el APK entregados se generan sin ese define: **ENFORCEMENT OFF**.
Para comprobar el contrato futuro sin cambiar el build entregado:

```powershell
flutter test --no-pub --dart-define=ATENA_COMMERCIAL_ENFORCEMENT=true test/commercial_policy_flow_test.dart
```

El define activa una política LOCAL de evaluación. No convierte el cliente en autoridad comercial segura de producción. Un build local o su almacenamiento pueden ser manipulados por su propietario: producción deberá verificar derechos en servidor.

## F–H. Matriz de comportamiento

| Plan institucional | OFF actual | ON de evaluación |
|---|---|---|
| Free | Puede probar nuevas solicitudes | No puede crear nuevas solicitudes digitales |
| Premium activo | Puede crear solicitudes | Puede crear solicitudes, sujeto a las reglas existentes |
| Histórico/desconocido/ausente | No agrega un bloqueo a los recorridos anteriores | No concede el permiso |
| Premium vencido/suspendido/enPrueba/sinPlan | No agrega un bloqueo comercial | No concede el permiso |

En todos los casos, la búsqueda y el perfil de información explícitamente publicada permanecen disponibles. La política comercial no publica registros privados, no cambia su orden en el buscador y no modifica el costo de ofertas.

## I–J. Cambio de plan e historial

La selección es institucional, no una identidad nueva. Free → Premium → Free → Premium conserva ID, propietarios/perfiles, grupos, áreas, configuración, catálogo y solicitudes.
La pantalla vuelve a leer el registro antes de guardar, usa `copyWith` para preservar el resto de los datos y actualiza la caché institucional que usan los menús. Así no muestra una selección anterior ni deja esa copia desactualizada para una edición posterior.
Un plan histórico no se reclasifica al guardar sin elegir explícitamente Free/Premium. Las fechas y estado operativo existentes se conservan. Para registros nuevos se usa estado operativo local activo; no significa pago. Los campos de fecha requeridos conservan el valor por defecto histórico del registro (inicio y fin a 30 días), únicamente por compatibilidad: **no se define ni ofrece una prueba o duración de suscripción Free/Premium**, ni se renueva ese período al cambiar de plan. La futura vigencia comercial requiere un contrato y autoridad remotos propios.
No se borran claves de promociones históricas. Se retiraron los controles y calculadores de precios/promociones de esta pantalla; sus cifras no se adoptan como política V1.

Downgrade bloquea sólo la creación nueva cuando ON. La solicitud A permanece visible y puede confirmarse con las reglas existentes; no se borra auditoría ni se libera ocupación. Al volver a Premium puede crearse C sin recrear la institución. La ocupación efectiva sigue siendo `max(ocupación persistida, solicitudes confirmadas)`; un plan Premium no garantiza cupo.

## K. Validación en servicio

`SolicitudesService.crearSolicitudDesdePerfil` comprueba la política justo antes de guardar la nueva solicitud, sus índices y notificaciones. Rechaza con `digital_enrollment_disabled` y un mensaje neutral. No se agregó la restricción al repositorio de bajo nivel ni a las transiciones de solicitudes existentes, para no bloquear su historia o gestión.
Las validaciones anteriores de contexto, grupo, área, duplicados y confirmación de cupos se conservan. Las pruebas invocan el servicio directamente y verifican que un rechazo comercial no deja escrituras de solicitudes/notificaciones.
Esto no constituye autenticación o transacción multiusuario de servidor. Los repositorios y servicios locales internos continúan teniendo el contrato local previo; el bloqueo comercial no sustituye la futura validación remota de identidad/propietario, capacidad y autorización.

## L. Interfaz

- Plan institucional: una selección Free/Premium para toda la institución, sin importes ni promociones; explica que es configuración local y que no acredita pago. Expone el modo de compilación sin permitir cambiarlo.
- Perfil público: con ON y Free muestra «Esta institución no recibe solicitudes digitales mediante Atena.»; conserva la información y el contacto publicado, con acción digital deshabilitada.
- Intención pública: comprueba la política antes de iniciar login; vuelve a pasar por la comprobación al retomar tras elegir perfil.
- Formulario de solicitud: comprueba al abrir y al enviar. El servicio vuelve a comprobar al crear, cubriendo cambios posteriores a la apertura de la pantalla.
- OFF: los botones permiten las pruebas habituales para Free y Premium.

## M–O. Descubrimiento, categorías y universidades

No se modifica el motor de búsqueda ni la publicación. Una institución Free y una Premium tienen la misma posibilidad de publicar explícitamente y aparecer con ofertas; sigue requiriéndose un operador autorizado.
Educación formal, universidad y Actividades y formación comparten la misma política institucional. No hay planes Premium separados por módulos ni para alumnos/familias.
**Plan Atena ≠ costo de oferta.** El filtro de gratuidad sigue usando `CostoOferta`; Premium con carrera gratuita y Free con actividad arancelada son casos cubiertos.

La futura ficha pública no reclamada es un concepto de **procedencia/administración verificada**, independiente del plan. No se representa como Free, no se genera ninguna ficha nueva y no se implementa reclamación. La futura verificación deberá preceder a la asignación autorizada de administrador y de plan; ni conocer un ID ni elegir Premium acreditará titularidad.

## P–S. Pruebas y builds

- Suite inicial ejecutada: **354 PASS**.
- Nuevas pruebas en `test/commercial_policy_flow_test.dart`: **30**, todas activas. Aislamiento de SharedPreferences y caché en cada caso.
- Suite final OFF: **384 PASS, 0 fallos, 0 omitidas**. Incluye las 30 pruebas nuevas.
- Batería comercial ON: **30 PASS, 0 fallos, 0 omitidas**. Misma política productiva compilada con el define; sin setter de pruebas ni expectativas de seguridad invertidas.
- Cubre servicio directo, planes desconocidos/estados, todas las categorías, costo independiente, caché antigua, downgrade/upgrade/historial/cupos, navegación anónima y login real con perfil e intención preservados, formulario ya abierto y cambio desde la pantalla institucional real.
- Widgets de la pantalla de planes: teléfono 360×800, texto 1,5×, temas claro y oscuro, sin excepciones de diseño.
- `flutter analyze --no-pub`: **76 avisos históricos, 0 nuevos, 0 errores**; conserva código 1 por esos avisos. Comparación de diagnóstico por archivo/mensaje con el informe público anterior, ignorando desplazamientos de línea.
- Build web JavaScript: **PASS**, código 0. Persisten las advertencias del ensayo Wasm de dependencias existentes (FFI/image); no se afirma soporte Wasm.
- Build Android Demo release: **PASS**, código 0.
- `git diff --check`: código 0, sin errores de whitespace. Permanecen advertencias Git sobre conversión futura LF/CRLF en archivos de unidades previas.

## T. APK

`C:\Users\Usuario\Desktop\ony\flutter_application_1\build\atena-free-premium-v1-evaluacion.apk`

Paquete `org.atena.demo.municipio`, etiqueta **Atena Demo**, versión 1.0.0/código 1, mínimo Android API 24, target 36.
Firma Android Debug de evaluación, certificado SHA-256 `06425f249fcc3cfec644d945f7c0c14e182fa3b98e2e227e25f7bed57e7aed5b`. La firma coincide con `atena-publica-v1-evaluacion.apk`; la identidad Demo se conserva.
Tamaño: 100,778,251 bytes. SHA-256 del APK: `72D9DBB1B5E9D0ED57422D865086EE80CE871C47D7967D9085986CFA91AA7D34`.
No se instala automáticamente. No hubo Android conectado: no se afirma prueba física.
Para actualizar Atena Demo, instalar encima de la versión anterior con la misma identidad/firma, sin desinstalar ni borrar datos. No se agregan migraciones destructivas ni se limpian preferencias. La compatibilidad del paquete y firma no sustituye la comprobación en el teléfono; conservar los datos existentes si Android rechaza la actualización.

## U. Git y archivos de la unidad

Seis archivos existentes modificados respecto del inicio de esta tarea:

1. `lib/services/plan_habilitacion_service.dart`
2. `lib/services/solicitudes_service.dart`
3. `lib/screens/instituciones/institucion_plan_page.dart`
4. `lib/screens/alumnos/alumno_solicitar_vacante_page.dart`
5. `lib/routes/solicitud_publica_intent.dart`
6. `lib/ui/catalogo_publico.dart`

Nuevos: `test/commercial_policy_flow_test.dart` y este documento. Los dos últimos archivos productivos ya eran untracked por la unidad pública anterior; no son una reimplementación nueva.
No se modificaron modelos, dependencias, main.dart, configuración Android ni fuentes Supabase en esta unidad. Build web/APK son artefactos generados e ignorados.
HEAD sin cambios. Staging vacío. Sin commit, push ni deployment. Todos los cambios anteriores siguen pendientes y conservados. Los cuatro históricos no se editaron: `auditoria_gestion_vacantes.txt`, `.backup-audit`, `.recovered`, `proyecto/`.
El estado completo de Git, incluida la extensa lista de trabajo anterior, se conserva en el informe de control externo indicado al final.

## V–W. Remoto y condiciones comerciales

**Supabase: ningún cambio remoto ni local de sus fuentes en esta unidad.** Sin migraciones, RLS, funciones ni pagos. Sin precios nuevos, descuentos, comisiones, límites de alumnos/operadores/almacenamiento ni condiciones comerciales definitivas. Alumnos/familias siguen sin plan comercial propio.

## X. Pendientes para producción

1. Cerrar la vinculación remota de identidades y autorización institucional; no asumir que los IDs locales acreditan identidad remota.
2. Implementar una autoridad comercial en servidor y reglas que validen el derecho al crear una nueva solicitud, sin aceptar el plan enviado por Flutter.
3. Definir explícitamente precios, vigencia y transiciones comerciales, y sólo entonces evaluar proveedor de pagos. La configuración actual no acredita suscripciones.
4. Proteger creación/confirmación de solicitudes y cupos mediante autorización y transacciones de servidor, conservando idempotencia y gestión del historial después del downgrade.
5. Verificar publicación compartida, aislamiento y revocación entre dispositivos. Los datos del catálogo y de solicitudes habituales siguen siendo locales al dispositivo.
6. Preparar firma de distribución y validación física; este APK usa firma Android Debug de evaluación.

No se presenta esta entrega como una suscripción segura de producción ni como sincronización remota de los módulos habituales.

Control de cambios externo: `C:\Users\Usuario\.codex\visualizations\2026\09\09\01a086de-6a08-7193-a5d9-c4afec5197bf\free-premium-v1`.
