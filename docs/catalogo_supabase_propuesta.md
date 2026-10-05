# Identidad y catálogo Supabase — candidato para revisión

Fecha: 26/09/2026. **Ninguna modificación ni prueba de escritura remota ejecutada.**
HEAD se conserva en `fb1388ccc14741e6e10cd12d36eca5712db59faf`.

Actualización local 02/10/2026: DTO/candidato en `schema_version: 2`; actividades
incluyen `description`, `ages` y `price`, con lista estricta de campos también en
SQL. No se aplicó el candidato. Solicitudes/cupos tienen un candidato separado y
pruebas preparadas, documentados en [cierre_producto_local_y_backend.md](cierre_producto_local_y_backend.md).

## 1. Qué falta del error 23514

Los metadatos aportados descartan la explicación de invisibilidad ordinaria por
RLS para el propietario postgres de SECURITY DEFINER. No se repitieron esas
consultas. La construcción local del primer link usa el mismo auth_user_id,
institution_id y operator_id que las inserciones del escenario ficticio. La
comparación local no demuestra una contradicción.

El disparador exige institución/operador/usuario coincidentes, operador activo y,
si es propietario, coincidencia con el propietario institucional. No exige que
todo operador sea propietario. No se eliminó ni modificó esa comprobación.

### Consulta exacta pendiente

Abrir `supabase/diagnostics/pilot_link_predicate_readonly.sql`. Ejecutar sus tres
bloques SELECT **por separado** en el SQL Editor del proyecto piloto. En el tercer
bloque sustituir únicamente los tres NULL por los valores ficticios exactos del
JSON de la petición que falló (UUID entre comillas seguido de ::uuid, textos
entre comillas seguidos de ::text). No usar contraseñas ni tokens. No reconstruir
un payload diferente a partir de otra ejecución del smoke test.

Necesitamos los resultados completos:

1. `function_sql`: cuerpo efectivo, no sólo SECURITY DEFINER y propietario.
2. Filas `tgname`, `tgenabled`, `trigger_sql`: permite detectar otro BEFORE trigger.
3. Una fila con `input_complete=true` y los siete predicados:
   institution_exists, operator_in_institution, auth_identity_matches,
   matching_operator_active, conditional_owner_check,
   complete_local_trigger_predicate y case_only_candidate.

Auditoría: el archivo contiene exclusivamente SELECT/CTE, introspección de
catálogo PostgreSQL y EXISTS sobre institución/operador. pg_get_functiondef y
pg_get_triggerdef obtienen texto; no ejecutan la función ni el trigger. No hay
INSERT/UPDATE/DELETE/DDL, cambios de permisos, ni invocación de funciones de la
aplicación. No se consulta auth.users ni columnas de contraseñas. El último
resultado sólo contiene booleanos. El texto de función es información interna,
por lo que debe compartirse únicamente en esta revisión.

Si todo coincide hoy, aún deben contrastarse el proyecto, el payload de aquel
envío y su momento transaccional. No se inventa una causa ni se propone una
migración correctiva de identidad sin esa evidencia.

## 2. Contrato HTTP separado del primer rechazo

| Operación del smoke | SQLSTATE esperado por el SQL local | HTTP |
| --- | --- | --- |
| Mantener usuario A, sustituir institución/operador por B | 23514 del BEFORE trigger | 400 |
| Usuario/institución/operador B coherentes, reutilizar local_account_id activo de A | 23505 por índice único | 409 |

Se corrigió exclusivamente la expectativa local: verifica ambos valores y no
acepta cualquier error. Ocho comprobaciones offline prueban éxito indebido,
códigos incorrectos, código ausente y fallo de red. No se ejecutó el smoke
remoto ni se leyó ninguna clave administrativa.

Fuente: https://docs.postgrest.org/en/v13/references/errors.html
La operación nueva del catálogo usa PT409 explícito para conflicto de versión,
no SQLSTATE40001 de error de serialización ni un fallo genérico de conexión.

## 3. Auditoría y correcciones locales acotadas

- IDs de institución/área/actividad/grupo estables por tipo e ID canónico, sin
  deducir identidad por nombres. Actividades curriculares no tienen entidad
  independiente: se conserva la etiqueta existente. En extras no se inventa una
  FK actividad-grupo desde actividadNombre. Es una limitación del dominio vigente.
- Área comprobable obligatoria. Datos históricos ambiguos y sobreocupación
  bloquean preparación. No se reasignan ni corrigen automáticamente.
- Horarios existentes conservados. Ocupación publicable ahora usa
  **max(persistida, confirmadas)**. El conteo comparte el matcher utilizado por
  SolicitudesService para curricular/extracurricular; no se suman dos veces.
- La API de lectura institucional de solicitudes devolvía una lista const vacía
  que el servicio intentaba ordenar. Se ordena una copia; no hay escrituras ni
  cambio de estados/consumo de cupos.
- Se añade occupied y availability al DTO. Disponible sólo con capacidad
  conocida positiva, margen y grupo habilitado. Curricular cero ya era inválido
  en el resolver común y sigue rechazado. Extra cero conserva su semántica local
  de cupo no gestionado: capacity/available null y availability=unmanaged, nunca
  se anuncia disponible. Esto NO cambia la regla local de inscripción extra.
- Estado de sincronización y versión se conservan. prepared_at y confirmed_at
  locales distinguen preparación y recepción del acuse, sin alterar la huella
  del contenido en cada consulta. Registros preparados anteriores sin esas
  fechas siguen legibles; al cambiar el DTO se requiere nueva preparación.
- confirmed_at local es hora de recepción, no prueba de fecha del servidor.
  El SQL candidato devuelve updated_at del servidor. Fuente sin fecha fiable
  no recibe una fecha de modificación inventada.
- No se exportan documentos, DNI, credenciales, contactos, propietarios,
  alumnado ni autoría individual. Ocupación es un agregado. Los nombres libres
  pueden contener texto personal escrito por el usuario: requieren revisión.

El catálogo sigue siendo local; el transporte real no está conectado. Las
pruebas de acuse/reintentos usan un sustituto, no validan RLS ni concurrencia de
Supabase. Los datos de solicitudes se consultan sólo localmente, sin migrarlos.
Una disponibilidad informativa local no certifica aún inventario multiusuario.

## 4. Diseño SQL candidato

Archivo: `supabase/candidates/20260926000000_catalog_review_only.sql`.
Fuera de `migrations/` para evitar aplicación incidental. **NO APLICADO**.
Requiere PostgreSQL con las migraciones piloto existentes, enlace validado,
revisión en BD desechable y revisión de concesiones reales antes de aprobarlo.
No se declara probado por PostgreSQL: no hay servidor local disponible aquí.

| Tabla | PK / relaciones | Contenido y acceso |
| --- | --- | --- |
| atena_private.catalog_namespaces | institution_id → institución existente; public_id único | Mapea identidad verificada al ID opaco local; sin nuevos propietarios |
| atena_private.catalog_scopes | institución+área → área existente; public_area_id único | Ámbito aprobado y contador de versión; sin nuevas asignaciones |
| public.atena_catalog_publications | area_id opaco → scope; institución opaca → namespace | Única proyección pública, JSON estricto, versión, estado, fecha servidor |
| atena_private.catalog_receipts | institución+área+operation_id; FK scope y operador | Idempotencia, huella, versión esperada/resultante, autor remoto y fecha |

Los dos mappings son correspondencias de IDs locales/remotos; no sustituyen
instituciones, áreas, operadores o capacidades. Se provisionarán únicamente con
verificación administrativa específica. Coincidencia de email/nombre o hashes
no autoriza el mapping. El cliente no puede crearlos ni editarlos.

Grupos y actividades se almacenan como arrays dentro del snapshot del área,
con IDs únicos por colección. No hay tablas paralelas de grupos operativos ni
FK por nombre; IDs de recursos sólo existen dentro del namespace del snapshot.
Un cliente no puede editar una fila del ámbito B enviando su ID en un catálogo
de A. La veracidad del contenido que publica A no se demuestra por el hash.
El namespace institucional se bloquea durante la publicación para impedir que
el mismo ID estable quede publicado a la vez en dos áreas de esa institución.
Mover un recurso requiere primero retirarlo de la publicación del área anterior;
no se reasigna automáticamente. La prueba con dos conexiones debe cubrirlo.

### Permisos propuestos

1. Añadir `catalog.publish` al CHECK de la lista de capacidades de las
   asignaciones actuales, preservando pilot.read/pilot.write. **No otorgarla a
   nadie automáticamente.** La candidata falla si el CHECK no es inequívoco.
2. Tablas privadas: RLS activada, sin políticas ni permisos para anon/authenticated.
3. Tabla pública: SELECT para anon/authenticated sólo si estado published y área
   vigente; no expone IDs administrativos ni actores. Withdrawn queda invisible.
4. Ninguna escritura directa de clientes: sin grants ni políticas INSERT/UPDATE/DELETE.
5. RPC de publicación SECURITY DEFINER con search_path vacío, permisos explícitos
   sólo authenticated, identidad desde auth.uid(), operador derivado (no parámetro),
   vínculo activo, propietario coherente si corresponde, asignación y área activas
   y catalog.publish. No basta enviar institución o área.
6. RPC de estado exige la misma autorización; permite conocer versión cuando el
   catálogo fue retirado o aún nunca publicado. No confirma el payload local.
7. Se propone USAGE de atena_private para anon únicamente para evaluar el helper
   booleano de visibilidad. No concede SELECT a tablas privadas ni EXECUTE a los
   otros helpers. Es un cambio de permisos propuesto que requiere aprobación.

Como el dueño de una tabla puede omitir RLS, la RPC valida y bloquea las filas de
autorización explícitamente; no pretende que RLS proteja una función privilegiada
por sí sola. Referencia: https://www.postgresql.org/docs/17/ddl-rowsecurity.html

### Publicación, versión e idempotencia

RPC recibe ámbito remoto, operación, versión esperada, JSON UTF-8 exacto, huella
SHA-256 y estado. La huella se verifica en servidor sobre el texto recibido antes
de convertirlo a jsonb. Un adaptador futuro deberá enviar catalogo.json tal cual,
sin reserializar ni cambiar la huella. Respuesta incluye ámbito, operación,
huella, nueva versión y updated_at servidor.

En una única transacción: autenticar y bloquear contexto, bloquear scope,
validar DTO y mapping, comprobar recibo, comparar versión, reemplazar snapshot,
incrementar versión e insertar recibo. Un retry exacto devuelve el mismo recibo;
la misma clave con otro payload/estado/base se rechaza. También se autoriza cada
retry, incluso después de una revocación. El recibo puede corresponder a una
versión histórica: no significa que siga siendo la última versión global.

No hay borrado físico ni cascadas. Eliminar grupos sustituye el snapshot sin
ellos. Catálogo publicado vacío conserva fila y versión con arrays vacíos.
Retirar el catálogo usa withdrawn, conserva versión y queda fuera de lectura
pública. Ausencia de fila, vacío confirmado y error de conexión son distintos.
No hay draft remoto: la preparación sigue local y no retira publicaciones.
Conflicto PT409 requiere resolución explícita; no rebase automático.

PK e índices únicos cubren scopes, namespaces, operaciones y áreas públicas.
Índice parcial institución/updated_at cubre sólo publicaciones visibles. No se
añade GIN ni búsqueda compleja antes de tener un caso de uso medido.

## 5. Pruebas remotas candidatas — NO EJECUTADAS

`tool/supabase_catalog_candidate_test.ps1` está deshabilitado por defecto y exige
ExecuteApprovedWrites. No es autorización para ejecutarlo ahora. Contexto por
variable de entorno en memoria, nunca archivos de tokens ni argumentos de shell.
No obtiene claves administrativas ni crea cuentas ni modifica permisos.

Fixture futura: dos instituciones ficticias dedicadas cuyo ID empiece por
atena-pilot-catalog-, dos áreas en A y cuatro usuarios Auth ficticios (propietario
A, operador independiente A, operador A sin capacidad y propietario B), todos
con links coherentes. Publicador A y operadorA: catalog.publish en AreaA; operador
sin capacidad: pilot.read; A conserva pilot.read/pilot.write para regresión.
AreaOther no asignada al operadorA. Mappings aprobados para sus IDs opacos.

ATENA_CATALOG_TEST_CONTEXT requiere Url, PublicKey, InstitutionA, InstitutionB,
AreaA, AreaOther, PublicInstitutionA, PublicAreaA, OperatorA, TokenA,
TokenOperatorA, TokenReadOnlyA y TokenB. No se documentan valores secretos.
OperatorA identifica al operador propietario autenticado con TokenA para la nota
del piloto anterior; TokenOperatorA pertenece a una segunda persona de A.
El mapping de scope debe incluir public_institution_id coherente con el namespace;
la FK compuesta impide combinar una institución pública con el área de otra.

| Caso | Comprobación candidata |
| --- | --- |
| A/B | Propietario y otro operador autorizado publican/incrementan versión |
| C | Operador sin catalog.publish: 403/42501 |
| D/E | Token B sobre A e IDs de área manipulados: 403/42501 |
| F | Lectura anónima published; withdrawn no aparece |
| G | Campo privado extra rechazado 400/22023; operadores no accesibles a anon |
| H | Misma operación no duplica ni aumenta versión |
| I | Base antigua rechazada PT409/409 sin overwrite |
| J | Revocar link y asignación ficticios por separado: token existente ya no escribe |
| K | Publicación vacía devuelve una fila con groups=[], no error ni ausencia |
| L | Escritura/lectura de nota piloto anterior sigue funcionando |

El script no declara PASS completo si no se ejecutan las revocaciones. Éstas
requieren otra intervención administrativa autorizada y no las implementa el
cliente. Tampoco reemplaza las 29 pruebas anteriores: deberán repetirse después
de autorizar el entorno remoto, junto con el circuito del primer vínculo.

Pruebas adicionales antes de aplicar a un piloto compartido:

- Dos conexiones, misma versión y operaciones distintas: sólo una confirma;
  la otra obtiene PT409. Idéntica operación concurrente: un recibo, una versión.
- Revocación concurrente con publicación: comprobar orden de locks; tras commit
  de revocación no se aceptan nuevas escrituras ni retries con el token anterior.
- Mismo operation_id con payload/base/estado distintos: rechazo sin cambios.
- JSON con datos privados anidados, IDs repetidos, tipos/nulos incorrectos,
  disponibilidad contradictoria y payload grande: rechazo, versión sin avanzar.
- Retirada, consulta de estado autorizada desde otra sesión y republicación.
- Intentos PATCH/DELETE directos, sesión vencida y ausencia de vínculo: denegados.
- La UI pública usa disponibilidad informativa, nunca confirma inscripciones.

## 6. Autorización siguiente

Primero aportar resultados de las tres consultas read-only con el payload
rechazado. Eso permitirá proponer la corrección de identidad si corresponde.
Después aprobar por separado: candidata SQL revisada en BD desechable, nueva
capacidad y grants de lectura pública, mappings y fixtures ficticios, pruebas
de publicación/revocación y regresión remota. No hace falta aprobar ni migrar
solicitudes, cupos, calendario o documentos en ese bloque.

Flutter permanece operativo sin esta migración. No se habilita un botón Publicar
ni se conecta el transporte real antes de validar servidor y mapping.

## 7. Validación local y archivos de esta unidad

- Suite final: 273 PASS, 0 omitidos (5 pruebas nuevas; las 16 anteriores conservadas).
- Pruebas específicas catálogo/cupos: 62 PASS antes del último test de pantalla;
  la suite final incluye todos esos casos y el test adicional de grupo suspendido.
- Contrato HTTP: 8 comprobaciones offline PASS; se evalúa sólo la función de
  assertions extraída del AST, nunca se ejecuta el script remoto completo.
- Candidato de pruebas remotas: sintaxis PowerShell comprobada; NO ejecutado.
- SQL candidato: revisión local; NO aplicado ni validado en PostgreSQL.
- flutter analyze: mismos 81 diagnósticos históricos, 0 nuevos, salida 1 por
  esos avisos; comparación contra el informe anterior ignorando números de línea.
- Build web JavaScript: PASS. Persisten avisos de dry run Wasm en dependencias.
- Build APK release final: PASS (95 MB),
  `build/atena-demo-catalogo-v2-2026-09-26.apk`. Paquete Atena Demo conservado.
  ADB no detecta Android conectado: no instalado ni probado en teléfono físico.
- git diff --check: PASS. No staging, commit, push ni deployment.

Archivos modificados respecto del comienzo de este bloque:

1. lib/services/catalogo_publicable_service.dart
2. lib/services/solicitudes_service.dart (lectura y conteo compartido; no migración)
3. lib/screens/instituciones/institucion_catalogo_page.dart
4. test/catalogo_publicable_flow_test.dart
5. tool/supabase_pilot_smoke.ps1 (sólo expectativa HTTP/SQLSTATE)
6. docs/catalogo_compartido_preparacion.md (enlace a esta revisión)

Archivos nuevos:

1. docs/catalogo_supabase_propuesta.md
2. supabase/candidates/20260926000000_catalog_review_only.sql
3. tool/supabase_catalog_candidate_test.ps1
4. tool/supabase_smoke_contract_test.ps1

La consulta de diagnóstico y la migración de identidad permanecen intactas.
Los cambios anteriores de Android, Visual V1, registro, plan y horarios permanecen
pendientes de commit. Esta unidad no volvió a modificar esos archivos ni el
acceso al catálogo ya incorporado en institucion_area_page.dart.
