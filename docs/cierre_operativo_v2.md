# Atena — cierre operativo local V2 · 28/09/2026

Esta unidad conserva el trabajo local previo a V2. No aplica cambios remotos,
no migra datos ni modifica credenciales, sesiones, solicitudes o cupos.

## Recorridos implementados

Institución → Administración → área → operador asignado → Administración del
área → Trayectoria del alumnado → inscripción confirmada → módulo educativo.

Cuenta de familia → perfil alumno → Área de alumno → Trayectoria educativa →
módulo. Las notificaciones educativas existentes también pueden abrir el módulo.

| Módulo | Alcance local operativo |
| --- | --- |
| Progreso | Porcentaje de avance de la inscripción; un registro actualizable por inscripción. |
| Boletines | Año, período, materias y notas ingresadas explícitamente, observaciones. Sin notas aparece incompleto. PDF local. |
| Títulos y certificaciones | Denominación, emisor, fecha, alumno y actividad; PDF con advertencia de ausencia de validación oficial externa. |
| Becas | Nombre, descripción, inicio/fin de vigencia y estado activo/inactivo. Sin decisiones automáticas de elegibilidad. |
| Sanciones | Motivo, tipo, detalle, fecha, fin opcional y estado. Conserva todas las revisiones; sin acción de borrado. |
| Equivalencias | Institución/materia de origen, materia de destino, institución de destino vinculada al contexto, fecha, observación y decisión aprobada/no aprobada. Sin decisiones automáticas. |

Todos permiten registrar, consultar y corregir; guardan autoría, inscripción,
grupo, área, institución, propietario/perfil del alumno, revisión y fecha.
Las lecturas posteriores reconstruyen los datos desde almacenamiento persistido.

## Permisos y privacidad

- Se exige sesión institucional coherente, contexto operativo vigente, área activa,
  operador activo/asignado e identidad canónica del alumno y su propietario.
- Se requieren capacidades por área `education.read` y `education.write`.
  El propietario conserva su regla existente; los demás operadores deben recibir
  explícitamente ambos permisos para escribir. Con sólo lectura no se muestran
  botones de carga/edición. No se agregan permisos a asignaciones históricas.
- Sólo se cargan alumnos con una inscripción confirmada de esa área y con
  propietario, perfil y documento verificables. No se vincula a nadie por DNI.
- Un registro nace interno. La publicación exige activar **Compartir con el
  alumno/familia**. La familia sólo consulta su perfil autenticado.
- Historial y metadatos desconocidos no se incluyen en la lectura familiar,
  incluso al publicar una corrección de un registro con campos internos antiguos.
- Las correcciones conservan versiones anteriores dentro del mismo registro.
  Se rechazan revisiones desactualizadas y duplicados de progreso o boletín
  para la misma inscripción/período/año. La escritura se serializa localmente.

## Persistencia y compatibilidad

Se reutilizan las claves existentes de `AlumnoService`:
`v3_alumno_progresos_`, `v3_alumno_boletines_`, `v3_alumno_titulos_`,
`v3_alumno_becas_`, `v3_alumno_sanciones_`, `v3_alumno_equivalencias_`,
seguidas por el perfil. No hay una segunda colección paralela.

Los campos de dominio mantienen sus nombres anteriores. Los metadatos se añaden
sin convertir ni borrar registros históricos. Las colecciones históricas como
mapa único o lista de mapas/JSON legibles se conservan. Una colección corrupta
produce error explícito y bloquea la escritura; no se reemplaza por una vacía.
Un guardado fallido no se anuncia como exitoso.

Los registros antiguos que no acreditan propietario/perfil, inscripción/área o
publicación explícita se conservan pero no se atribuyen ni publican automáticamente.
Su recuperación visible requiere verificar esos datos; no se inventa una migración.
Los dos modelos históricos de títulos siguen existiendo: se conserva el mismo
almacenamiento y no se hace una refactorización destructiva.

## Correcciones necesarias adicionales

- `PdfBase` declaraba `margin` junto con `pageTheme`: el generador rechazaba la
  combinación. Se conservan los márgenes dentro de `pageTheme` solamente.
- El separador fijo del pie PDF usa un guion compatible con la fuente actual.
- Los errores de formulario se muestran también junto al área visible de la
  pantalla mediante un aviso; no quedan ocultos por el desplazamiento.
- Formularios desplazables, fecha con selector y entrada validada, diseño
  dependiente del tema existente, tarjetas adaptables y estados vacíos.

## Pruebas

`test/education_operational_flow_test.dart` incorpora 22 casos:
notificación real; seis formularios a 320×640, modo oscuro y texto doble;
seis recorridos de creación/corrección/reingreso/publicación; identidades y
áreas ajenas; capacidades/revocación; compatibilidad y corrupción; concurrencia,
duplicados y boletín incompleto; generación de PDFs; propietario contradictorio;
registro histórico con documento contradictorio; recorrido completo
menú → área → operador → administración → seis módulos y
reingreso de institución/familia; validación de formulario con texto ampliado.

Las pruebas usan cuentas ficticias y almacenamiento aislado. El recorrido de
pantalla utiliza el selector real de áreas y operadores. La autenticación se
realiza mediante los servicios reales; no se afirma una prueba física Android.

## Límites concretos

- Datos exclusivamente locales; la sincronización entre dispositivos sigue fuera
  de esta unidad. No hay cambios en Supabase ni en el bloqueo 23514.
- Registros históricos sin identidad/publicación verificable requieren revisión
  antes de mostrarse. Inscripciones sin área canónica tampoco se atribuyen.
- PDF: generación comprobada; impresión/compartición dependen de la plataforma.
  La fuente Helvetica heredada no garantiza caracteres fuera de su repertorio
  latino. No se incorporó una descarga de fuentes ni una dependencia nueva.
- La emisión local no valida títulos oficiales, integridad del plan de estudios
  ni una escala de calificaciones externa. El operador registra la decisión.
- La prueba en un teléfono físico y la exportación mediante su diálogo del
  sistema deben realizarse al instalar el APK; no se sustituyen con widget tests.

## Uso en demostración

Instalar el APK V2 encima de Atena Demo, sin desinstalar ni borrar datos. Entrar
en una institución ficticia, elegir área y operador y abrir Trayectoria del
alumnado. Si está vacío, primero debe existir una solicitud confirmada con
identidad y área verificables. Registrar información, publicar sólo lo destinado
a la familia y cambiar a la cuenta/perfil correspondiente para consultarla.

El próximo paso mínimo es comprobar este mismo recorrido en el Android de
demostración, incluido cierre/reapertura y exportación PDF, sin abrir módulos nuevos.

## Archivos de V2

Modificados sobre la base de trabajo previa:

- `lib/models/instituciones/operador_institucional.dart`
- `lib/screens/alumno/alumno_area_page.dart`
- `lib/screens/alumnos/alumno_notificaciones_page.dart`
- `lib/screens/instituciones/institucion_area_page.dart`
- `lib/screens/instituciones/institucion_operadores_page.dart`
- `lib/services/alumno_service.dart`
- `lib/services/pdf/pdf_base.dart`

Nuevos en esta unidad:

- `lib/models/alumnos/modulo_educativo.dart`
- `lib/screens/alumnos/trayectoria_educativa_page.dart`
- `lib/screens/instituciones/institucion_trayectoria_page.dart`
- `lib/services/trayectoria_educativa_service.dart`
- `lib/services/pdf/pdf_trayectoria.dart`
- `test/education_operational_flow_test.dart`
- `docs/cierre_operativo_v2.md`

El estado Git incluye además cambios anteriores a esta unidad; no se descartaron
ni incorporaron al staging. `main.dart`, Android, Supabase y sus herramientas no
recibieron cambios V2. No se agregaron dependencias.

## Resultado final de validación

- Suite completa: **303 PASS, 0 omitidas, 0 fallos** (281 de base + 22 nuevas).
- Análisis: **81 avisos históricos, 0 nuevos**; comparación sin diferencias al
  ignorar desplazamientos de línea. El comando retorna 1 por esos avisos existentes.
- Web JavaScript: **PASS**. Permanecen los avisos previos del diagnóstico opcional
  de WebAssembly en `share_plus` e `image`; no impiden el build JavaScript.
- Android release Demo: **PASS**. `git diff --check`: **PASS**.
- APK: `build/atena-demo-operativa-v2-2026-09-28.apk`, 100.201.520 bytes.
- SHA-256 APK: `6C473ADFBFCAE3BC4A457A46343184F928451DFECA440ACF80C1EB76266B99A3`.
- Package: `org.atena.demo.municipio`, versión `1.0.0` / código `1`, Android mínimo 24.
- Firma verificada y coincidente con V1:
  `06425f249fcc3cfec644d945f7c0c14e182fa3b98e2e227e25f7bed57e7aed5b`.
- APK V1 conservado; SHA-256 sin cambios.
- ADB: ningún dispositivo conectado. No hubo instalación ni prueba física.
- Staging vacío; sin commit, push ni deployment. HEAD conservado en
  `fb1388ccc14741e6e10cd12d36eca5712db59faf`.
- Auditoría y dos respaldos históricos comparados por hash, sin cambios;
  `proyecto/` no intervenido, con estado interno limpio. Ningún archivo previo eliminado.

Los seis módulos son **OPERATIVOS EN EL CIRCUITO LOCAL VERIFICADO**. Esta
clasificación no equivale a sincronización remota, migración automática del legado,
validación oficial de documentación ni prueba física del APK.
