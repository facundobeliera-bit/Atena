# Catálogo institucional: preparación local

> Este documento conserva la entrega local inicial. La revisión posterior de
> ocupación efectiva, fechas, contrato HTTP y SQL candidato está en
> [catalogo_supabase_propuesta.md](catalogo_supabase_propuesta.md).

## Alcance de esta unidad

Se agrega una proyección publicable de los modelos vigentes, no un segundo
catálogo editable. La pantalla está accesible desde Funciones del área.
Conserva Visual V1 y permite revisar y preparar una versión local. No publica,
no consume cupos y no modifica solicitudes, autenticación ni Supabase.

`CatalogoPublicableService` usa el resolver curricular común de Gestión/alumno
y los servicios extracurriculares existentes. Revalida institución, área,
operador y capacidades groupsRead/groupsWrite. El almacenamiento nuevo es
exclusivamente `atena_catalog_outbox_v1_<hash(institución,área)>`.

La proyección contiene nombre y ubicación general institucional, área,
actividades y grupos con horario, estado y disponibilidad informativa. No copia
modelos completos, credenciales, CUIT, dirección, contacto, documentos,
alumnos ni autoría del operador. Los textos libres requieren revisión humana:
una lista de campos permitidos no detecta nombres personales escritos en ellos.

## Identificadores y compatibilidad

Los IDs se derivan con SHA-256 de versión de formato, tipo, institución e ID
canónico. Renombrar no cambia la identidad. No se inventan asociaciones entre
actividad y grupo a partir de su nombre: el modelo actual conserva
`actividadNombre`, no una clave de actividad verificable. Se proyecta como
etiqueta, no como clave foránea.

Los grupos sin área explícita, corruptos o sobreocupados impiden preparar el
catálogo; no se asignan a otra área ni se normalizan silenciosamente. En grupos
extracurriculares con cupo no gestionado se usa null, no una disponibilidad cero.
Actividades extracurriculares se seleccionan por el módulo de origen del área.
Los curriculares se presentan como grupos con su etiqueta de actividad.

Estos IDs no prueban propiedad. Antes de habilitar publicación multiusuario,
el servidor debe vincular el namespace local con una institución remota
verificada. Dos instalaciones con copias divergentes no se fusionan por nombre,
correo o coincidencia aparente de IDs. Falta resolver ese vínculo.

## Estados y contrato del transporte

- Sólo local: no hay preparación persistida.
- Pendiente: snapshot guardado, aún sin acuse.
- Confirmado: acuse exacto de institución, área, operación, huella y versión.
- Cambios locales: fuente actual distinta de la última preparación/confirmación.
- Error de conexión: resultado incierto; conservar payload y clave para reintentar.
- Conflicto: servidor tiene otra versión; no sobrescribir ni rebasar automáticamente.

Errores y conflictos siguen visibles aunque cambie la fuente local. Un catálogo
vacío es una versión válida; datos corruptos no se convierten en vacío. El
journal inválido no se descarta. Preparar no escribe en las fuentes históricas.

`TransporteCatalogo` es únicamente el límite para un futuro adaptador remoto.
No tiene implementación Supabase ni se expone envío en la pantalla. Los tests
usan un servidor en memoria explícito: NO validan transacciones ni RLS remotas.

Una misma preparación tiene una clave determinista por ámbito, versión base y
huella. Reintentos conservan el contenido original. El recibo permite comprobar
el incremento de versión. La cola local serializa operaciones dentro de un
isolate, no entre dispositivos. La persistencia y la autorización locales no
sustituyen garantías del servidor ni protegen frente a un cliente manipulado.

## Propuesta del próximo bloque remoto (no aplicada)

1. Cerrar el rechazo del vínculo verificado con evidencia de la petición fallida.
2. Autorizar por separado esquema, RLS y RPC de catálogo por institución/área.
3. Mantener cabecera de versión y snapshots públicos por ámbito, más un registro
   de idempotencia. La RPC debe validar JWT, vínculo vigente, operador y capacidad
   del área incluso para reintentos; no confiar en IDs enviados por Flutter.
4. En una transacción: deduplicar operación verificando huella, comprobar versión
   esperada, sustituir sólo el snapshot de esa área (incluido vacío), incrementar
   versión y conservar acuse. Conflicto no modifica ninguna fila.
5. Incorporar adaptador de red que distinga autorización, conflicto y conexión;
   probar pérdida de respuesta, revocación y concurrencia con dos sesiones reales.
6. Habilitar lectura pública únicamente de snapshots aprobados y probar búsqueda
   desde otro dispositivo. Solicitudes y consumo de cupos quedan fuera: requerirán
   otro contrato transaccional, no escrituras del catálogo desde las familias.

## Diagnóstico 23514

La evidencia aportada por el usuario confirma SECURITY DEFINER, propietario
postgres y bypass de RLS sin FORCE RLS. No se atribuye el rechazo a RLS.

La función local requiere simultáneamente: operador en la institución enviada,
auth_user_id coincidente, operador activo y, sólo si es propietario, coincidencia
con owner_auth_user_id de esa institución. Permite operadores no propietarios.
El script construye el primer link desde los mismos valores que utiliza al crear
institución y operador. No se demuestra una contradicción local de ese primer link.

Faltan el cuerpo efectivo completo, otros triggers relevantes y los resultados
del predicado con el JSON ficticio exacto que falló. Se preparó exclusivamente
lectura en `supabase/diagnostics/pilot_link_predicate_readonly.sql`. No se ejecutó
remotamente. Un resultado positivo actual no prueba el estado al momento del error.

Dos observaciones sobre el script existente (sin modificarlo):

- Sus comprobaciones PowerShell usan -eq, insensible a mayúsculas en texto. No
  demuestran igualdad exacta de los IDs; esto es una limitación, no causa probada.
- El caso negativo deliberadamente contradictorio usa ExpectConflict (HTTP409),
  pero el BEFORE trigger local lanza23514, que PostgREST convierte en HTTP400.
  Debe comprobarse ese código SQLSTATE y rechazo, conservando409/23505 para el
  duplicado. Esta discrepancia posterior NO explica el fallo del primer link válido.

Referencia de traducción HTTP: https://docs.postgrest.org/en/v13/references/errors.html

No se propone eliminar el chequeo de propietario ni ampliar permisos. No hay
causa remota demostrada que justifique una migración correctiva todavía.

## Validación

El test `catalogo_publicable_flow_test.dart` cubre proyección real, aislamiento,
permisos revocados, persistencia local, IDs estables, preparación simultánea,
vacío explícito, corrupción, datos históricos ambiguos, conexión incierta,
conflicto, acuse contradictorio y pantalla real.

Resultados del 26/09/2026:

- Suite Flutter: 268 PASS, 0 omitidos, código 0 (16 nuevos del catálogo).
- Registro institucional: se conserva persistencia de cuenta/perfil/institución
  y plan antes de activar contexto; recuperación parcial exige las comprobaciones
  de ambas credenciales/propiedad existentes. Las 4 regresiones correspondientes
  pasan, incluida la denegación de credencial ajena.
- Plan y horarios: las 7 pruebas existentes pasan; el plan se presenta como
  estado local que no acredita pago; horas imposibles se rechazan.
- Análisis: 81 avisos, código 1 por los avisos históricos. Comparación contra el
  informe Visual V1: mismos diagnósticos, 0 nuevos (ignorando desplazamientos de línea).
- Build web JavaScript: PASS. El dry run de Wasm advierte incompatibilidades
  preexistentes de share_plus/image; no se declara compatibilidad Wasm.
- Build APK release: PASS, 95 MB. Artefacto:
  `build/atena-demo-catalogo-local-2026-09-26.apk`.
  Paquete `org.atena.demo.municipio`, versionCode 1, versionName 1.0.0.
  SHA-256: `E6E496589749FA2037B6D184066EF07FDFC63F0DDE851313060837F0B39A4218`.
- git diff --check: PASS. Git también avisa sobre LF/CRLF de archivos anteriores;
  no son errores de whitespace ni se normalizaron esos archivos.
- ADB no detectó dispositivos Android; falta probar la instalación y el recorrido
  en un teléfono físico. La prueba de pantalla nueva es automatizada (widget).

## Control de cambios

HEAD inicial y final: fb1388ccc14741e6e10cd12d36eca5712db59faf. Staging vacío.
No commit, push, deployment, consultas con credenciales ni cambios remotos.
Los cambios anteriores de Android, registro/plan/horarios, Visual V1 y piloto
permanecen pendientes. P1-B y P1-D permanecen consolidados sin reimplementación.

Esta unidad agrega únicamente servicio, pantalla y test de catálogo, este documento
y la consulta SQL de diagnóstico. En la pantalla de área preexistente agrega
importación y acceso al catálogo; conserva los cambios Visual V1 anteriores.
La comparación SHA-256 de los 303 archivos preexistentes controlados (incluido
proyecto/) sólo registra diferencia en esa pantalla de área autorizada. Los cuatro
elementos históricos y los restantes cambios previos permanecen idénticos.
