# Cierre operativo local V1 — 28/09/2026

Esta entrega mejora el circuito local demostrable. No declara terminada toda
Atena ni habilita sincronización entre dispositivos.

## Correcciones verificadas

- Las listas nuevas de solicitudes de cuenta y pendientes institucionales ya
  no intentan ordenar una colección inmutable vacía.
- Una diferencia de mayúsculas o acento en «Mañana/manana» no impide confirmar
  una solicitud curricular. El horario sigue formando parte de la validación.
- Búsqueda y selección de vacantes consideran la ocupación efectiva:
  máximo entre ocupación guardada y confirmaciones. La lectura no modifica
  grupos. Los suspendidos curriculares quedan fuera de la selección; en extras
  se respetan inactividad y capacidad global de la actividad.
- Gestión curricular edita el área abierta y conserva los grupos de otras
  áreas. Se rechaza reutilizar el identificador de un grupo ajeno al área.
  Los históricos sin área se reconocen sólo por área única o actividad exacta;
  no hay migración masiva ni escrituras durante la lectura.
- Las solicitudes nuevas heredan el área del grupo cuando está definida.
  La decisión institucional comprueba también el área actual del grupo;
  la lista filtra las solicitudes que tienen otra área explícita.
- El selector extracurricular espera al primer frame antes de leer traducciones.
- El formulario de solicitud y su confirmación son desplazables con texto grande.
- Documentación tiene acceso directo desde el área del alumno, separado de PDF.

## Evidencia y límites del recorrido

`test/local_operational_journey_test.dart` utiliza almacenamiento ficticio aislado:
selección y confirmación del plan de una institución nueva en pantalla; creación
de áreas, asignación de operador, actividad y grupos con APIs locales reales;
registro de cuenta y perfil alumno por APIs reales; selección del perfil en
pantalla; búsqueda, perfil institucional, vacante curricular y envío en pantalla;
selector extracurricular y envío en pantalla; cambio a la cuenta institucional,
confirmaciones en pantalla con área/operador; nuevo ingreso y reconstrucción de
la aplicación del alumno, persistencia de ambas confirmaciones y acceso a documentos.

No equivale a manipular todos los formularios en un Android físico. Las pruebas
anteriores de registro, horarios, capacidad, permisos, comunicaciones, documentos,
sesión y contraseña siguen formando parte de la regresión completa.

`test/operative_vacancies_flow_test.dart` cubre vacíos, formato de turno,
disponibilidad efectiva, suspendidos, extras sin gestión de cupos, conservación
entre áreas y rechazo de una decisión en el área incorrecta.

## Matriz operativa resumida

| Circuito | Estado y límite |
|---|---|
| Registro, login, perfiles y logout | Local; cubierto por regresión y recorrido nuevo |
| Plan, áreas, operadores y capacidades | Local; sin contratación ni autenticación remota de operadores |
| Búsqueda, grupos, solicitudes y cupos | Local en la misma instalación; recorridos curricular y extra comprobados |
| Calendario, comunicaciones, respuestas y documentación | Implementación local; pruebas existentes de persistencia y permisos |
| PDF del alumno | Disponible; impresión/compartir dependen del dispositivo |
| Progreso, boletines, títulos, becas, sanciones y equivalencias | Parciales: modelos/notificaciones no equivalen a recorridos completos; no presentarlos como terminados |
| Recuperación de acceso | Informativa; el restablecimiento sin verificar identidad sigue deshabilitado |
| Catálogo compartido y colaboración entre dispositivos | Pendientes de backend; no se publican datos desde este bloque |
| Supabase piloto | Conservado; error 23514 y SQL candidato sin intervención remota |

## Control de cambios

Sin commit, staging, push ni deployment. Se conservaron los cambios anteriores.
Auditoría y respaldos conservan sus hashes previos; `proyecto/` no recibió
operaciones de escritura y su repositorio interno continúa limpio.
No se modificaron dependencias, configuración Android, autenticación, Supabase,
políticas ni datos personales reales durante esta unidad.

Validación física pendiente: instalar encima de Atena Demo, sin desinstalar ni
borrar datos; repetir registro/ingreso, grupos, solicitud, confirmación, logout
y reapertura.

## Resultado final

- Suite completa: 281 PASS, 0 omitidas (8 pruebas nuevas).
- Análisis: 81 avisos históricos, 0 nuevos; salida 1 por los avisos existentes.
- Web JavaScript y Android release: PASS. Persisten los avisos previos del dry run Wasm.
- `git diff --check`: PASS; staging vacío; HEAD continúa en `fb1388c`.
- No se detectó teléfono Android conectado.
- APK: `build/atena-demo-operativa-v1-2026-09-28.apk` (99.611.656 bytes).
- Paquete: `org.atena.demo.municipio`, versión 1.0.0, código 1.
- Firma comparada con el APK anterior: idéntica y verificación satisfactoria.
- SHA-256 del APK: `DCF88B89CC373C25902106F2018606D86046675A775AEF76964933680B106384`.

Archivos de esta unidad (además de este documento):

- `lib/screens/alumno/alumno_area_page.dart`
- `lib/screens/alumnos/alumno_seleccion_grupo_extracurricular_page.dart`
- `lib/screens/alumnos/alumno_solicitar_vacante_page.dart`
- `lib/screens/alumnos/alumno_vacantes_curriculares_page.dart`
- `lib/screens/instituciones/institucion_gestion_vacantes_page.dart`
- `lib/screens/instituciones/institucion_mis_solicitudes_page.dart`
- `lib/services/alumno_instituciones_search_service.dart`
- `lib/services/institucion_grupos_autorizacion_service.dart`
- `lib/services/solicitudes_service.dart`
- `test/local_operational_journey_test.dart` (nuevo)
- `test/operative_vacancies_flow_test.dart` (nuevo)
