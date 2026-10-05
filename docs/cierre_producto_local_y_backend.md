# Atena — cierre local y preparación del backend

## Actualización del sprint — 05/10/2026

El checkpoint `1c2f29accd201e8d797f079d3cf22ab7caab8295` consolida el trabajo
anterior y fue subido normalmente a `fix/buscar-instituciones-alumno`. Los apartados
fechados más abajo son el registro histórico de sus respectivas unidades.

### Backend preparado y comprobado localmente

- `CatalogoSupabaseRepository` implementa el transporte del catálogo/outbox existente:
  publicación explícita, versión, retiro y reintento con la misma clave/huella.
  Un rechazo de autorización no se convierte en éxito ni en lista vacía.
  Lectura pública paginada mediante `atena_catalog_read`; reutiliza `FichaPublicaInstitucion`
  y `OfertaPublica`, sin modelos canónicos privados. No hay fallback silencioso local.
- Proyección schema 3: educación formal, universidad, precio gratuito/arancelado/a
  consultar, horario, edades, descripción y requisitos. Sólo campos de presentación
  explícitamente publicados; no owner, credencial, alumno, solicitud ni teléfono
  privado. El servidor conserva compatibilidad schema 2 para outboxes pendientes.
- `SolicitudesSupabaseRepository` envía únicamente perfil verificado, grupo público y
  UUID de operación; para decidir, ID de solicitud y estado. Nunca envía cupos,
  propietario, rol ni plan como prueba de autorización. No genera sesiones ni vínculos.
  El consumidor debe conservar el UUID en reintentos; no sustituye el repositorio local.
- Candidatos existentes de catálogo y solicitudes ampliados y EJECUTADOS en PostgreSQL
  17.11 desechable de localhost. Se corrigió una referencia SQL ambigua en la validación
  de duplicados que impedía publicar. Confirmación atómica, pool de grupo/actividad,
  `max(persistida, confirmadas)`, capacidad positiva, comprobación de vínculos vigentes,
  actividad publicada activa, idempotencia y estados terminales. La actividad se mapea
  administrativamente por ID público verificado; nunca se infiere por nombre.
- La lectura pública recalcula disponibilidad sobre los mismos pools e índice de
  confirmadas. No oculta sobreocupación; un recurso sin mapeo comprobado no anuncia
  cupos solicitables. La tabla de publicaciones conserva la instantánea/versionado;
  usar la RPC para disponibilidad vigente. La confirmación vuelve a comprobarla.
- Política comercial sólo administrable en servidor, OFF inicialmente para desarrollo.
  ON exige entitlement Premium activo para NUEVAS solicitudes; Free conserva catálogo,
  historial y gestión/reintento de solicitudes existentes. Flutter no puede cambiarla.

No se activó este backend en las pantallas habituales: conservan el modo local y su
enforcement OFF. Publicación/lectura remota y solicitudes quedan como adaptadores
opcionales comprobados, no como sincronización habilitada ni demostrada entre teléfonos.
El retiro remoto requiere conservar su clave/versionado hasta recibir confirmación;
no se agregó todavía un botón remoto ni una cola de retiro en la interfaz habitual.

### Identidad y autorización remota pendiente

La migración local admite propietario coherente y operador independiente; ambos se
probaron en SQL. IDs contradictorios y propietario inconsistente producen 23514.
Esto NO identifica la causa histórica remota. Siguen faltando el cuerpo completo de
la función instalada, todos los triggers efectivos y el predicado con el payload
ficticio exacto del fallo. Usar únicamente
`supabase/diagnostics/pilot_link_predicate_readonly.sql`; no se modificó el trigger.

Después de aclarar esa evidencia, se requiere autorización separada para:

1. Aplicar al proyecto piloto `20260926000000_catalog_review_only.sql` y después
   `20260928000000_requests_capacity_review_only.sql`, ambos en `supabase/candidates/`.
   No aplicar automáticamente todas las migraciones ni cambiar la identidad histórica.
2. Provisionar EXCLUSIVAMENTE fixtures verificadas: vínculos, capacidades específicas,
   namespaces/scopes, perfiles solicitantes y mapeos grupo/actividad/pools con ocupación
   inicial comprobada. No se crean automáticamente desde Flutter o por coincidencia de correo.
3. Ejecutar el smoke candidato de catálogo y el circuito de solicitudes con Auth/PostgREST
   real y dos sesiones. Los scripts remotos siguen deshabilitados sin autorización explícita.
4. Sólo al definir activación comercial remota: entitlements verificados y
   `update atena_private.commercial_policy set enforcement_enabled=true where singleton;`.
   No hay precios/pagos ni escrituras remotas ejecutadas por este sprint.

Falta integrar la selección de identidades remotas verificadas en el recorrido habitual,
habilitar explícitamente los adaptadores después de aceptación remota, persistir reintentos
de solicitudes/retiros en esa interfaz y probar dos dispositivos. Calendario,
comunicaciones, módulos educativos, documentos y notificaciones siguen locales;
no se amplió su migración con las etapas previas todavía sin aceptación remota.

### Validación de esta actualización

402 tests Flutter PASS (18 nuevos), 0 omitidos; 76 avisos estáticos históricos,
0 nuevos. 48 comprobaciones PostgreSQL locales PASS, incluida la regresión SQL
existente y concurrencia real, y 8 comprobaciones offline del smoke PASS.
Build web JavaScript PASS; APK de evaluación PASS:
`build/atena-v1-sprint-local-2026-10-05.apk`, paquete `org.atena.demo.municipio`.
SHA-256: `73DB27894663173B7FFD47BD96CBB37D82259F5691E80C7B5F65A791C27D791D`.
No instalado ni probado en un teléfono durante este sprint. `git diff --check` PASS.
No se ejecutaron las 29 comprobaciones contra Supabase: requieren escrituras remotas
no autorizadas en este bloque. Las pruebas locales no se presentan como pruebas remotas.

Los cuatro históricos continúan fuera de Git. No se modificaron dependencias,
configuración de deployment, credenciales locales, Supabase remoto ni datos del teléfono.

Fecha: 02/10/2026. Base de esta unidad: Operativa V2, 303 pruebas, 81 avisos.
HEAD conservado: `fb1388ccc14741e6e10cd12d36eca5712db59faf`.
No commit, staging, push, deployment ni cambios remotos. No sustituye la aceptación
física Android ni declara terminada la plataforma multiusuario.

## A–C. Implementación local y problemas corregidos

| Circuito | Estado y alcance comprobable |
|---|---|
| Documentación | **OPERATIVO LOCAL**: institución/área/operador autorizado solicita a una inscripción confirmada; familia adjunta bytes de PDF/PNG/JPEG; ambas consultan; vencimiento y eliminación locales existentes. |
| Comunicaciones extracurriculares | **OPERATIVO LOCAL**: destinatarios obtenidos de solicitudes confirmadas canónicas, sin IDs manuales ni padrón auxiliar divergente; institución, área y autor validados; calendario y notificaciones persistidos. |
| Comunicaciones curriculares | **OPERATIVO LOCAL**: selección vuelve a validar inscripción, propietario y área antes de escribir; el grupo seleccionado limita destinatarios. |
| Información educativa | **OPERATIVO LOCAL**: seis módulos V2 conservados; publicar genera aviso genérico sin copiar calificaciones, sanciones ni contenido interno; actualización no duplica aviso. |
| Dirección | **OPERATIVO LOCAL**, designación organizacional mínima sobre el operador existente. Sólo propietario validado designa. No cambia owner, identidad ni capacidades; no habilita administración automáticamente. |
| Búsqueda | **OPERATIVO LOCAL**: texto de actividad, edades con límites y turno; precio desconocido no se interpreta como gratuito ni como pago. |
| Indicadores de vacantes | **OPERATIVO LOCAL**: ocupación usa máximo de persistida/confirmadas; disponibilidad excluye grupos suspendidos y respeta estados. Lecturas fallidas no se anuncian como padrón vacío. |
| PDFs | **OPERATIVO LOCAL**: exportación de ficha revalida sesión y vuelve a leer ficha vigente; guardar en web utiliza exportación del navegador; acceso real a registros educativos desde PDFs. Generación automática comprobada, diálogos del sistema no verificados físicamente. |

La nueva pantalla documental reemplaza el ingreso manual de identidades y la
carga simulada por una institución en nombre del alumno. Se mantienen las claves
históricas; solicitudes sin área verificable se conservan, sin atribuirlas a otra.
Los nuevos permisos `documents.read`/`documents.write` se conceden al propietario
por su contrato existente; delegados necesitan asignación explícita.

Archivos de hasta 2 MiB, almacenados localmente como referencia data URI. Se valida
tipo básico por cabecera, no se realiza análisis antivirus. No representa almacenamiento
remoto protegido ni persistencia transaccional de una base SQL. No subir datos reales
confiando en garantías SINGLE/REQUIRED/CLOSE: no están implementadas.

Se rechazan colecciones documentales corruptas sin convertirlas en listas vacías.
Subidas simultáneas del mismo perfil se rechazan mientras hay otra en curso. Si el
archivo persistió pero no su estado, el reintento con el mismo contenido completa
la solicitud sin duplicar el archivo; un contenido diferente no lo sobrescribe.
Un error de persistencia no debe mostrarse como éxito. El bloqueo es local a la
ejecución, no coordina pestañas ni dispositivos.

Los recorridos anteriores de registro, registro institucional parcial, planes,
horarios, cupos, solicitudes, sesiones, PBKDF2 y los seis módulos educativos se
conservan y están incluidos en la regresión. No se vuelve a atribuir como nuevo
todo lo desarrollado en V1/V2.

## D. Preparado para backend, sin aplicar

1. Catálogo existente: DTO y candidato actualizados a **schema_version 2** para
   incluir descripción, edades y precio de actividades. Los identificadores siguen
   siendo estables. La huella cambia al cambiar el documento; una preparación antigua
   debe revisarse/prepararse nuevamente, no marcarse publicada. Sin copiar entidades
   privadas completas, contactos, credenciales ni alumnos. Revisar textos libres.
2. `supabase/candidates/20260928000000_requests_capacity_review_only.sql`:
   vínculos de solicitantes verificados administrativamente, recursos por ámbito,
   capacidad por grupo y actividad, lectura RLS, RPC create/decide. No acepta un
   operador, institución o área arbitrarios en la decisión: los resuelve desde JWT
   y registros autorizados. Confirmación y consumo ocurren en una transacción.
3. Cupos: bloqueos de filas ordenados, máximo de ocupación persistida/confirmadas,
   idempotencia por operación y transición terminal, rechazo de sobreocupación sin
   normalizar contadores. En extracurricular, el mapeo al pool de actividad debe
   verificarse administrativamente; no se infiere por nombre.
4. Prueba PostgreSQL transaccional en `supabase/tests/requests_capacity_regression.sql`
   y protocolo de dos conexiones en `requests_capacity_concurrency.md`.

**Candidatos NO ejecutados ni certificados**: no hay psql/PostgreSQL/Docker disponible.
La revisión del texto no demuestra transacciones, sintaxis SQL, RLS ni concurrencia
reales. Requieren entorno desechable y revisión/autorización separada antes de
aplicarse. La suite Flutter no cuenta estas pruebas como aprobadas.

El catálogo sigue teniendo una interfaz de transporte, no un adaptador Supabase
conectado. Solicitudes/cupos remotos tampoco tienen adaptador Flutter. La disponibilidad
remota deberá consultarse al servidor al operar y refrescarse después de cada decisión;
un snapshot del catálogo no garantiza un cupo. No se debe modificar el catálogo para
consumir plazas desde el cliente.

## E–F. No implementado y bloqueos concretos

- **BLOQUEADO — vínculo 23514**: la evidencia local no demuestra una contradicción
  del primer fixture. Hay evidencia previa de SECURITY DEFINER/propietario postgres;
  eso no demuestra el cuerpo efectivo ni el estado de la transacción fallida. Faltan
  función completa, todos los triggers y resultados del predicado con el JSON ficticio
  exacto rechazado. Usar los tres SELECT de
  `supabase/diagnostics/pilot_link_predicate_readonly.sql`. No se eliminó la condición
  del propietario, no se atribuye sin prueba a RLS y no se reejecutó el smoke remoto.
- **OPERATIVO REMOTO previamente validado**, solamente piloto aislado de notas y
  autenticación ficticia: 29 comprobaciones históricas. No se repitieron en esta
  unidad ni se extrapolan a catálogo, solicitudes o módulos habituales.
- **NO IMPLEMENTADO**: sincronización habitual entre dispositivos de catálogo,
  solicitudes/cupos, calendario/comunicaciones, educación y documentación. Los
  correspondientes circuitos de la aplicación siguen siendo locales.
- **BLOQUEADO — emancipación/transferencia de titularidad**: existen servicios
  parciales (`EmancipacionTransferService`/`CuentaService.emanciparPerfilAlumno`),
  sin recorrido normal conectado. Cambian propietario y solicitudes, pero no ofrecen
  verificación independiente de ambos titulares ni transferencia atómica de todos
  los documentos/notificaciones/índices. Conectarlos tal cual puede perder acceso
  o concederlo a otra identidad. No se ejecutaron ni se añadieron botones. Requiere
  definir quién autoriza el traspaso y qué acceso conserva la familia de origen.
- **NO IMPLEMENTADO**: publicación familiar de croquis institucional. El modelo
  institucional no determina una versión pública sin datos de otros alumnos. Se
  retiró la tarjeta sin acción de PDFs y se conectaron allí los documentos educativos
  reales; no se anunció que un croquis privado ya esté disponible para familias.
- Recuperación de contraseña sin verificación continúa deshabilitada. La informativa
  y su navegación funcionan; recuperación real necesita proveedor/verificación remota.
- Identidad individual remota de operadores, autoridad de Dirección y políticas de
  revocación remota no se sustituyen por selección local ni por un booleano de cargo.

## G. Pruebas automáticas

- Suite completa final: **318 PASS, 0 omitidas, 0 fallos**; 303 base + 15 nuevas.
- `test/final_product_flows_test.dart`: **15 PASS**, incluye permisos/aislamiento,
  carga real/cancelación/corrupción/reintento/concurrencia documental, comunicaciones,
  autoría, Dirección, filtros, navegación PDF y pantalla estrecha con texto ampliado.
- Test previo de capacidades: fixture actualizado para persistir la inscripción
  que antes sólo existía en memoria; assertions conservadas.
- Análisis: **81 avisos históricos, 0 nuevos**, comparación normalizada contra V2;
  código 1 del analizador por esos avisos, no se presentan como análisis sin avisos.
- Diagnóstico offline de assertions remotas: **8 PASS**, sin llamadas de red.
- Candidato PowerShell de catálogo: sintaxis PASS; no se ejecutó contra Supabase.
- SQL y carreras de dos sesiones: **NO EJECUTADOS**, no incluidos en el total PASS.

## H–I. Builds y control de cambios

Build web JavaScript: **PASS**, `build/web`. El diagnóstico opcional WebAssembly
avisa incompatibilidades de dependencias (dart:ffi/dart:html e image); no se compiló
ni se declara soporte Wasm. Build Android release Demo: **PASS**. `git diff --check`:
**PASS**, código 0. No se instaló ni verificó físicamente esta versión en un teléfono.

APK: `build/atena-demo-cierre-local-2026-10-02.apk`, 100.463.828 bytes.
SHA-256: `4F2D88456ACEB9A180365F74FEF1EC87DF09957C2F55C43262367EBC9918E28E`.
APK V2 conservado, hash idéntico al informado el 28/09.
Package `org.atena.demo.municipio`, versión 1.0.0/código 1, Android mínimo 24.
Firma verificada: `06425f249fcc3cfec644d945f7c0c14e182fa3b98e2e227e25f7bed57e7aed5b`,
coincidente con V2. Actualización sobre la misma aplicación, sin desinstalar.
No se borran datos. La firma demo existente no es una firma para distribución
productiva/Play Store.

Staging vacío; HEAD conservado. Se preservaron cambios anteriores a esta unidad.
Auditoría y dos respaldos comparados con hashes de entrada; `proyecto/` sin cambios
internos y sin intervención. No se cambiaron dependencias, login, P1-B/P1-D, main,
configuración Android ni migraciones remotas durante esta fase final.

## J. Qué falta para terminar Atena

**Necesario, no mejoras opcionales:**

1. Obtener los tres resultados de sólo lectura del 23514 y demostrar la causa;
   autorizar y probar únicamente la corrección que se derive de esa evidencia.
2. Validar vínculos independientes, revocación y asignaciones con usuarios ficticios;
   definir/probar acreditación de titularidad histórica antes de incorporar datos reales.
3. Revisar/aprobar y ejecutar los candidatos de catálogo y solicitudes/cupos en un
   entorno desechable; superar RLS, JWT manipulado, reintentos y carreras reales.
4. Implementar adaptadores Flutter sobre esos contratos ya verificados y la lectura
   autorizada de disponibilidad vigente; resolver conflictos sin sobrescribir locales.
   Probar publicación A → consulta B → solicitud → confirmación atómica → lectura B.
5. Aprobar contratos y conectar calendario/comunicaciones, luego información educativa
   y finalmente archivos/documentación, con destinatarios, autoría, revocación, acceso
   y retención verificados en servidor. No basta copiar SharedPreferences a tablas.
6. Resolver los contratos de emancipación y visibilidad pública de croquis antes de
   conectarlos. No sacrificar identidad/privacidad para quitar un pendiente visual.
7. Campaña final Android/web con archivos reales ficticios, diálogos de exportación,
   reinicio y dos dispositivos; configurar distribución/firma/recuperación verificadas
   sólo después de aprobar el entorno remoto. No se exige realizarla ahora para
   continuar el desarrollo autorizado, pero sigue siendo aceptación pendiente.

**Opcional y no iniciado:** organigrama avanzado, analytics, chat general, enciclopedia
de actividades y cambios decorativos adicionales. No bloquean los contratos anteriores.

Conclusión: el cierre local avanzó con implementación y pruebas; **Atena completa
multiusuario todavía no está terminada**. Las dependencias anteriores son concretas,
no una afirmación de que bastaría instalar este APK o aplicar SQL sin validarlo.

## Archivos de esta fase (respecto de la base V2, no de HEAD)

Modificados:

- `docs/catalogo_supabase_propuesta.md`
- `lib/models/instituciones/operador_institucional.dart`
- `lib/screens/alumnos/alumno_documentos_page.dart`
- `lib/screens/alumnos/alumno_pdfs_page.dart`
- `lib/screens/instituciones/institucion_documentos_page.dart`
- `lib/screens/instituciones/institucion_extracurricular_modulo_base.dart`
- `lib/screens/instituciones/institucion_gestion_vacantes_page.dart`
- `lib/screens/instituciones/institucion_operadores_page.dart`
- `lib/services/alumno_instituciones_search_service.dart`
- `lib/services/catalogo_publicable_service.dart`
- `lib/services/documentos_temporales_service.dart`
- `lib/services/extracurriculares_service.dart`
- `lib/services/institucion_emisiones_service.dart`
- `lib/services/institucion_operadores_service.dart`
- `lib/services/trayectoria_educativa_service.dart`
- `supabase/candidates/20260926000000_catalog_review_only.sql`
- `test/catalogo_publicable_flow_test.dart`
- `test/institution_operator_capabilities_flow_test.dart`
- `tool/supabase_catalog_candidate_test.ps1`

Nuevos:

- `docs/cierre_producto_local_y_backend.md`
- `lib/services/documentacion_operativa_service.dart`
- `lib/ui/documento_local_actions.dart`
- `supabase/candidates/20260928000000_requests_capacity_review_only.sql`
- `supabase/tests/requests_capacity_concurrency.md`
- `supabase/tests/requests_capacity_regression.sql`
- `test/final_product_flows_test.dart`

## Estado Git completo al entregar

Incluye trabajo previo, no solamente esta fase.

```text
 M android/app/build.gradle.kts
 M android/app/src/main/AndroidManifest.xml
 M lib/main.dart
 M lib/models/instituciones/operador_institucional.dart
 M lib/screens/alumno/alumno_area_page.dart
 M lib/screens/alumnos/alumno_buscar_instituciones_page.dart
 M lib/screens/alumnos/alumno_documentos_page.dart
 M lib/screens/alumnos/alumno_institucion_perfil_page.dart
 M lib/screens/alumnos/alumno_notificaciones_page.dart
 M lib/screens/alumnos/alumno_pdfs_page.dart
 M lib/screens/alumnos/alumno_seleccion_grupo_extracurricular_page.dart
 M lib/screens/alumnos/alumno_solicitar_vacante_page.dart
 M lib/screens/alumnos/alumno_vacantes_curriculares_page.dart
 M lib/screens/instituciones/institucion_area_page.dart
 M lib/screens/instituciones/institucion_documentos_page.dart
 M lib/screens/instituciones/institucion_extracurricular_modulo_base.dart
 M lib/screens/instituciones/institucion_gestion_vacantes_page.dart
 M lib/screens/instituciones/institucion_menu_page.dart
 M lib/screens/instituciones/institucion_mis_solicitudes_page.dart
 M lib/screens/instituciones/institucion_operadores_page.dart
 M lib/screens/instituciones/institucion_plan_page.dart
 M lib/screens/landing/landing_page.dart
 M lib/services/alumno_instituciones_search_service.dart
 M lib/services/alumno_service.dart
 M lib/services/documentos_temporales_service.dart
 M lib/services/extracurriculares_service.dart
 M lib/services/institucion_emisiones_service.dart
 M lib/services/institucion_grupos_autorizacion_service.dart
 M lib/services/institucion_operadores_service.dart
 M lib/services/pdf/pdf_base.dart
 M lib/services/solicitudes_service.dart
 M supabase/README.md
 M test/institution_operator_capabilities_flow_test.dart
 M tool/supabase_pilot_smoke.ps1
?? auditoria_gestion_vacantes.txt
?? docs/
?? lib/models/alumnos/modulo_educativo.dart
?? lib/screens/alumnos/trayectoria_educativa_page.dart
?? lib/screens/instituciones/institucion_catalogo_page.dart
?? lib/screens/instituciones/institucion_trayectoria_page.dart
?? lib/services/catalogo_publicable_service.dart
?? lib/services/documentacion_operativa_service.dart
?? lib/services/pdf/pdf_trayectoria.dart
?? lib/services/solicitudes_service.dart.backup-audit
?? lib/services/solicitudes_service.dart.recovered
?? lib/services/trayectoria_educativa_service.dart
?? lib/ui/atena_workspace.dart
?? lib/ui/documento_local_actions.dart
?? proyecto/
?? supabase/candidates/
?? supabase/diagnostics/
?? supabase/migrations/20260920000001_atena_pilot_verified_links.sql
?? supabase/tests/
?? test/catalogo_publicable_flow_test.dart
?? test/education_operational_flow_test.dart
?? test/final_product_flows_test.dart
?? test/institution_plan_and_hours_test.dart
?? test/institution_registration_android_flow_test.dart
?? test/local_operational_journey_test.dart
?? test/operative_vacancies_flow_test.dart
?? test/visual_workspace_navigation_test.dart
?? tool/supabase_catalog_candidate_test.ps1
?? tool/supabase_smoke_contract_test.ps1
```
