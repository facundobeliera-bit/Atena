# Atena pública V1 — cierre local

Fecha de validación: 5 de octubre de 2026.

## A. Estado inicial real

Base canónica: raíz de este repositorio, rama `fix/buscar-instituciones-alumno`, HEAD `fb1388ccc14741e6e10cd12d36eca5712db59faf`.
Había numerosos cambios de la consolidación, correcciones Android y preparación Supabase sin confirmar; se conservaron. Staging vacío. Línea base ejecutada nuevamente: **323 PASS, 0 fallos, 0 omitidos**.
No se utilizó el rediseño externo ni `proyecto/` como fuente vigente.

## B. Arquitectura de la capa pública

Se extiende `CatalogoPublicableService`, no se crea otro catálogo de gestión. La institución y sus grupos siguen siendo los registros canónicos. `FichaPublicaInstitucion` y `OfertaPublica` son proyecciones con campos públicos explícitos.
Una publicación local por área se guarda bajo `atena_catalog_public_local_v1_<hash(institución, área)>`. No renombra ni reemplaza las claves existentes. El outbox remoto mantiene su esquema y comportamiento previo.
La lectura anónima utiliza exclusivamente publicaciones explícitas; revalida existencia, área activa, estado y disponibilidad mediante los resolutores canónicos. No divulga registros internos. Las fuentes corruptas se omiten sin repararlas ni escribir listas vacías. Un cambio de nombre/grupo/horario requiere republicar para no solicitar una propuesta distinta de la mostrada.

## C–D. Portada y búsqueda anónima

Portada con búsqueda visible, Educación formal, Actividades y formación, Universidades y Opciones gratuitas. Se conservan los accesos a las cuentas de ambos roles.
Ruta pública `/buscar`. Busca institución y oferta: nombre, grupo, programa/carrera y descripción publicada. Normaliza mayúsculas, tildes y espacios en consultas, sin normalizar ni fusionar identificadores.
Una instalación sin publicaciones muestra un estado vacío real; no se añadieron datos ficticios de relleno.

## E–H. Taxonomía, universidades e instituciones mixtas

- Educación formal conserva los grupos curriculares existentes.
- Actividades y formación conserva los módulos extracurriculares y sus actividades.
- La publicación formal admite presentación Escolar, Superior/institutos o Universidad. Universidad permanece en Educación formal; usa Carrera/programa y Comisión/grupo. Los nombres de actividad y grupo siguen siendo los canónicos. No se migraron enums, IDs ni claves escolares ni se construyó un ERP universitario.
- Las áreas publicadas se reúnen por institución. Una institución mixta puede aparecer por cualquiera de sus ofertas, incluso si la palabra buscada no está en su nombre.

## I–J. Costos y filtros

Costo por oferta: Gratuito, Arancelado o Consultar/no informado. Nunca se usa el plan Atena para decidirlo ni para ocultar publicaciones Free.
Gratuito exige un valor explícito reconocido (Gratuito, Gratis, Sin costo/cargo o importe cero). Un importe positivo reconocido es arancelado. Valores vacíos o ambiguos quedan a consultar. El precio formal se indica al publicar; en actividades proviene del catálogo existente si hay una coincidencia inequívoca.
Filtros: categoría, costo, localidad, provincia, país, modalidad, turno/horario, texto de edades publicado, presentación formal y vacantes informadas. Las condiciones se cumplen en la misma oferta; no se cruzan el precio de una con la categoría de otra.
Sin GPS, distancias inventadas ni filtro estatal/privada deducido del plan. Los filtros de horario y edades buscan texto informado, no calculan elegibilidad personal. No se inventan requisitos ausentes.

## K. Perfil público

Presenta nombre, descripción, imágenes públicas disponibles, ubicación, modalidad, teléfono público y ofertas con horario, edades, costo y disponibilidad cuando existen. No expone correo de acceso, contraseña, propietario, operadores, alumnos, documentación privada ni solicitudes.
La ficha declara su procedencia local y no otorga un sello de verificación externa.

## L. Transición a autenticación

Una intención tipada conserva institución, grupo y categoría durante login, registro y selección explícita del perfil. No lleva una identidad autorizante del alumno.
Después del ingreso, la solicitud utiliza la cuenta y el perfil que valida `CuentaService`. Se vuelven a consultar publicación, grupo y sesión antes de abrir el formulario canónico. Las reglas existentes vuelven a verificar identidad/cupos al enviar.
La intención permanece durante ese recorrido de navegación; no se guarda como una sesión paralela ni como redirección arbitraria. Cerrar/reiniciar la aplicación durante el login no conserva una inscripción pendiente: debe elegirse nuevamente la oferta.

## M–N. Seguridad y compatibilidad

Publicar/retirar requiere contexto operativo vigente y capacidad `groupsWrite` del área; la inspección administrativa mantiene `groupsRead`. Explorar no activa perfiles ni cierra sesiones. Sólo `/buscar` se añade como ruta pública; no se abren rutas administrativas.
Se conserva el arranque anterior: una sesión persistente válida puede reconstruir su área. Desde alumno, cuenta e institución hay acceso al buscador, con retorno mediante Back sin logout.
`main.dart`, servicios de sesión/credenciales, solicitudes, cupos, modelos canónicos, Supabase y archivos de dependencias no se modificaron en esta unidad. Los módulos educativos anteriores siguen cubiertos por su regresión.

## O–P. Pruebas y análisis

**354 PASS, 0 fallos, 0 omitidos**: los 323 anteriores y 31 nuevos.
Los nuevos escenarios cubren publicación explícita, lectura anónima, institución/oferta, tildes, universidad/carrera, institución mixta, costos, filtros, privacidad, autorización por área, retirada, eliminación, suspensión, disponibilidad canónica, corrupción, persistencia, sesión institucional intacta, cambios que requieren republicación, ruta pública directa y el recorrido real anónimo → login → perfil → solicitud persistida. También comprueban conservación de la intención al abrir registro y el retorno al Área de alumno sin perder identidad.
Diseño en widget tests: 320×640, 412×892 y 1440×1000, ambos temas y texto 1,6×; las pruebas existentes de portada mantienen texto 2×. La única adaptación de tests anteriores precisa el scroll vertical de la portada, ahora que el campo de texto también contiene un scroll horizontal; no se retiraron assertions.
`flutter analyze`: **76 avisos históricos, 0 nuevos, 0 errores**. El comando conserva salida 1 por esos avisos; no se presenta como análisis sin avisos.
`git diff --check`: código 0. Git advierte sobre conversión futura LF/CRLF de cambios anteriores, sin errores de whitespace.

## Q–R. Builds y prueba visual

- `flutter build web --no-pub`: PASS, JavaScript. Persisten advertencias del ensayo Wasm por FFI/paquetes anteriores; no se afirma soporte Wasm.
- `ATENA_ANDROID_DEMO=1 flutter build apk --release --no-pub`: PASS.
- Navegador real local: portada, entrada al buscador sin login, búsqueda y vacío sin publicaciones; vista móvil 360×800 y cambio de tema claro/oscuro comprobados visualmente. Los recorridos con datos publicados/login/solicitud se ejecutaron como pruebas Flutter, no como una prueba física ni con datos reales en el navegador.
- Vista local servida en `http://127.0.0.1:8774/`. Sin deployment remoto.

## S. APK de evaluación

Ruta: `C:\Users\Usuario\Desktop\ony\flutter_application_1\build\atena-publica-v1-evaluacion.apk`.
Tamaño: 100.778.251 bytes.
SHA-256: `5BAA5B753D7E162B4E3C519575C965072E763840D3F70DFBD4C915B8949F6E97`.
Paquete: `org.atena.demo.municipio`. Etiqueta: Atena Demo. Versión 1.0.0, código 1. Android mínimo API 24, target 36.
Firma de evaluación Android Debug, SHA-256 del certificado: `06425f249fcc3cfec644d945f7c0c14e182fa3b98e2e227e25f7bed57e7aed5b`.
Coincide con el paquete/firma de `atena-consolidada-v1-evaluacion.apk`: actualiza esa Atena Demo, no se instala separada. No hay migración destructiva ni borrado de almacenamiento. Para conservar los datos, instalar encima; no desinstalar ni borrar datos. La compatibilidad de paquete/firma está verificada, la actualización física no: no había Android conectado y no se instaló automáticamente.

## T. Control de cambios

HEAD y rama sin cambios; staging vacío; sin commit, push ni deployment. Se conservaron los cambios previos. `auditoria_gestion_vacantes.txt`, `.backup-audit`, `.recovered` y `proyecto/` no se editaron.

Archivos de esta unidad:

- lib/models/catalogo/ficha_publica.dart (nuevo)
- lib/routes/solicitud_publica_intent.dart (nuevo)
- lib/ui/catalogo_publico.dart (nuevo)
- test/public_discovery_flow_test.dart (nuevo)
- docs/atena_publica_v1.md (nuevo)
- lib/services/catalogo_publicable_service.dart
- lib/routes/atena_router.dart
- lib/screens/landing/landing_page.dart
- lib/screens/alumnos/alumno_buscar_instituciones_page.dart
- lib/screens/alumnos/alumno_institucion_perfil_page.dart
- lib/screens/alumno/alumno_area_page.dart
- lib/screens/auth/alumno_login_page.dart
- lib/screens/auth/alumno_registro_page.dart
- lib/screens/cuentas/cuenta_home_page.dart
- lib/screens/instituciones/institucion_catalogo_page.dart
- lib/screens/instituciones/institucion_menu_page.dart
- test/visual_workspace_navigation_test.dart

Varios de estos archivos ya tenían trabajo previo sin confirmar. Esta lista describe el delta de la unidad, no una autorización de staging ni el conjunto completo pendiente en Git. Build web/APK son artefactos generados e ignorados. La comparación de huellas contra la línea base no mostró cambios adicionales en archivos existentes fuera de esta lista.

## U. Límites reales y uso

Los datos siguen en el dispositivo: publicar aquí no hace visible la institución en el teléfono o navegador de otra familia. Las comprobaciones locales no sustituyen RLS, autenticación remota ni validación multidispositivo. No se tocaron piloto, SQL, diagnóstico 23514 ni permisos remotos.
El catálogo descubre ofertas con grupos existentes y área comprobable; no reasigna históricos ambiguos ni inventa grupos para actividades que aún no los tienen. Los cupos no gestionados se muestran a consultar y no entran en el filtro de vacantes conocidas. La publicación muestra una versión explícita de datos públicos; nombres/horarios modificados deben republicarse. Un precio ambiguo no se presenta como gratuito.

Para probar: ingresar como institución → área y operador con permiso → Catálogo del área → Publicar en el buscador local → revisar presentación/costo y confirmar. Luego explorar desde la lupa o cerrar sesión y buscar. Es posible retirar esa publicación sin borrar los registros canónicos. Si se desea usar datos ficticios, crearlos conscientemente mediante los flujos existentes; este cambio no precarga instituciones nuevas.

## V. Próxima unidad

Evaluar esta versión en Android y revisar el circuito de publicación con una institución ficticia. Después, conectar la proyección pública a un catálogo compartido sólo cuando se cierre la vinculación de identidades y su autorización remota. Paywall, pagos, datos reales y sincronización masiva permanecen fuera de esta unidad.
