# Alta institucional y recuperación V1

## Estado operativo — 13/10/2026

La migración `20261010000000_institution_onboarding.sql` fue aplicada y validada en el piloto `eaegvxxxkvhdukbkydvy` el 11/10. **No volver a aplicarla**. Los dos correos ficticios se confirmaron mediante sus enlaces reales; 60 comprobaciones Auth/JWT y 5 controles finales aprobaron solicitud, aprobación, propietario, áreas, invitaciones/revocación, borrador/publicación, inscripción/confirmación y cupo compartido. No hubo prueba física ni recorrido visual completo. El solicitante de inscripción fue un perfil ficticio provisionado administrativamente: no acredita alta autónoma de alumnos/familias.

La comparación de las 33 tablas previas y cuentas Auth anteriores confirmó que los datos históricos y el escenario de teléfonos quedaron intactos. Un falso positivo del script de integridad incluía la credencial de una cuenta NUEVA entre los históricos; se resolvió usando la línea base anterior a la campaña. No se relajaron controles. El revisor temporal quedó deshabilitado al finalizar.

## Retorno de correo: cambio local preparado, activación pendiente

Lectura de configuración real el 13/10: `site_url=http://localhost:3000`, `uri_allow_list` vacío, `mailer_autoconfirm=false`, registro por correo habilitado, SMTP propio ausente, límite de envío 2/hora. La plantilla usa `{{ .ConfirmationURL }}`. `InstitutionOnboarding.register` no envía `emailRedirectTo`: Supabase toma Site URL. Android no declara un intent-filter de callback. El registro no debe convertirse en aprobación ni sesión institucional automática.

Solución mínima: página estática `web/auth/return.html`, incluida en el build web; **no publicada todavía**. Es HTML estándar para navegador Android o web, indica volver a Atena e ingresar, limpia query/fragmento antes de navegar, no intercambia ni almacena tokens, no carga SDK/recursos externos y no interpreta la URL como prueba de identidad. Los errores del proveedor se muestran como mensaje fijo, sin reflejar descripciones o secretos. No requiere deep links ni cambios en el contrato PKCE, roles, sesiones o contraseñas. Un código PKCE descartado no se reutiliza: el ingreso posterior usa las credenciales en Atena.

Destino propuesto en el hosting EXISTENTE, no un dominio nuevo:

`https://atena-staging.facundobeliera.workers.dev/auth/return.html`

La consulta HTTP desde este entorno devolvió **403** tanto en raíz como en esa ruta; no prueba que la página esté publicada ni accesible. No activar el retorno hasta resolver ese acceso y comprobar HTTP 200 del archivo exacto, su CSP y contenido. Puede ser una restricción del punto de consulta: no se atribuye la causa sin evidencia.

Secuencia que requiere autorización remota específica:

1. Autorizar publicación de la página en el Worker existente, sin cambiar rutas, bindings o SPA ni publicar indiscriminadamente otra aplicación. Comprobar que el inicio web del mismo origen sea la versión piloto deseada; si no, acordar primero su actualización. Este sprint no desplegó nada.
2. Después de verificar acceso, cambiar **sólo** `site_url` del proyecto piloto a la URL exacta anterior. Cuerpo preparado para la API de configuración Auth:

```json
{"site_url":"https://atena-staging.facundobeliera.workers.dev/auth/return.html"}
```

3. Mantener confirmación de correo y plantilla del proveedor, no agregar comodines, no cambiar `uri_allow_list`, SMTP, usuarios, RLS ni permisos. El retorno por defecto también afecta otros flujos Auth: la página no completa recuperación/cambio de contraseña ni OAuth. Es adecuada para el contrato actual de confirmación y regreso al ingreso; no habilitar esos otros flujos sin su revisión.
4. Autorizar una comprobación real con correo ficticio; confirmar en servidor, enlace vencido/reutilizado y login posterior. No registrar URL completa, query, tokens ni códigos en observabilidad del hosting; comprobar configuración de logs antes de activar. Hasta entonces: redirección **PARCIAL**, nunca PASS remoto.

Alternativa evaluada: deep links Android requieren esquema/intent-filter y allow-list, no sirven a quien abre el correo en otra computadora, y no son necesarios para confirmar correo y luego ingresar. No se añadieron. Antes de usuarios reales, definir entrega de correo propia/autorizada y sus límites; no se activó SMTP ni servicio pago.

Fuentes: [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls), [deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking).

## Contrato institucional

1. Acceso institucional → Registrarse abre registro Supabase en modo multiusuario. El acceso local conserva su formulario anterior. Registro no escribe cuentas locales ni concede permisos institucionales.
2. Confirmar el correo mediante Supabase y volver a Ingresar. El cliente inicializa PKCE con el almacenamiento existente de Supabase Flutter. La página de retorno preparada arriba mantiene ese contrato; la configuración remota aún no cambió.
3. Cuenta → Incorporación y administración institucional: enviar nombre y referencia institucional. El servidor toma `auth.uid()` de la sesión vigente, valida confirmación de correo y genera el ID de solicitud. Un UUID de operación sólo identifica reintentos.
4. Un revisor habilitado ve solicitudes pendientes en esa misma pantalla. Debe verificar externamente la identidad del solicitante y su autorización para representar a la institución. La aplicación exige una confirmación explícita y una referencia de revisión, y registra revisor, fecha y decisión. **No existe verificación oficial ni automática de representación legal.** La referencia no debe contener documentos personales ni secretos; remite al expediente protegido del administrador.
5. No se admite autoaprobación. Una solicitud rechazada no crea institución. No se asocian instituciones históricas por coincidencia de correo o nombre. Colisiones requieren revisión administrativa; este bloque no incorpora un procedimiento para reclamar instituciones existentes.
6. Aprobar crea atómicamente institución, operador propietario, vínculo verificado, área inicial y capacidades `catalog.publish`, `requests.read`, `requests.decide`. Los IDs los genera el servidor. El ancla `pilot-remote-*` no acredita propiedad de ninguna cuenta local histórica.
7. El propietario crea/renombra áreas y delega sólo esas capacidades disponibles en su propia asignación. No puede elegir `is_owner` en una invitación. La invitación se dirige a un correo verificado, una institución y un área; vence a las 48 horas y vuelve a verificar la autoridad del emisor al aceptarla. El destinatario la ve tras iniciar sesión; no se agregó un servicio opcional de envío de invitaciones por correo.
8. Un operador activo puede aceptar otra área por invitación expresa. Un operador revocado no se reactiva mediante una invitación antigua. La revocación desactiva vínculo, asignaciones e invitaciones pertinentes antes de desactivar el operador, respetando el trigger de identidad.
9. Volver a Cuenta actualiza el contexto autorizado. Publicación y solicitudes usan los RPC existentes: borrador, publicación, inscripción y confirmación atómica de cupo. No hay fallback local de éxitos remotos.

Limitaciones deliberadas: la aceptación no convierte al invitado en propietario; la reactivación de operadores revocados y reclamación de instituciones históricas requieren revisión y no se implementan automáticamente. La administración de áreas cubre creación y nombre; no se eliminan áreas con datos ni se alteran sus publicaciones por efectos implícitos.

## Habilitar al primer revisor sin editar tablas

Requiere autorización para elegir una identidad de revisor con correo confirmado, distinta del solicitante. La migración no habilita automáticamente a ningún usuario. El revisor ficticio de la campaña quedó deshabilitado; no reutilizarlo como un permiso permanente.

Plan local (UUID real de prueba a proporcionar, no inventar):

```text
python tool/onboarding_admin.py --reviewer-user UUID
```

Sólo tras autorización remota específica:

```text
python tool/onboarding_admin.py --reviewer-user UUID --execute-authorized-pilot eaegvxxxkvhdukbkydvy
```

La herramienta solicita la credencial administrativa sin mostrarla; permanece en memoria y se usa sólo para el RPC restringido a `service_role`. Nunca llega a Flutter. `--disable` prepara/revoca exclusivamente el rol de revisor; no afecta Auth ni otros roles. El uso de la herramienta debe quedar registrado por el administrador responsable; la auditoría SQL diferencia esta configuración confiable de las decisiones hechas con el JWT individual del revisor. Las aprobaciones habituales se realizan con la sesión normal del revisor en Flutter, no con esa clave.

### Uso cotidiano y reemplazo

- Designación inicial: el responsable verifica la identidad y el UUID del revisor, documenta el alcance y autoriza la herramienta anterior. La credencial administrativa sólo la custodia el administrador; el revisor NO la necesita.
- Acceso diario: Atena Multiusuario → Ingresar → Cuenta → **Incorporación y administración institucional**. Esa pantalla ya lista solicitudes pendientes autorizadas; permite **Revisar y aprobar** o **Rechazar**. No se necesita otro panel ni editar tablas.
- Revisar externamente la representación; indicar una referencia no sensible. Aprobar exige confirmar explícitamente la revisión. La solicitud propia no muestra acciones y el servidor también impide autoaprobación. Decisión y configuración de revisor quedan registradas en `onboarding_audit`; la solicitud conserva revisor, referencia, fecha y resultado.
- Reemplazo: autorizar al nuevo UUID confirmado; verificar acceso; deshabilitar al anterior con `--disable` mediante la misma herramienta. Si hay sospecha de compromiso, revocar primero al anterior. No asignar permisos institucionales ni cambiar Auth para efectuar el reemplazo. La siguiente decisión del revisor revocado debe ser rechazada, incluso con un diálogo abierto; un timeout se resuelve consultando estado/auditoría antes de repetir.
- El alcance del revisor es revisión institucional del piloto, no administración global de Supabase. La auditoría de designación identifica el UUID objetivo como actor confiable; la identidad del administrador que ejecuta la herramienta requiere registro operativo externo. No afirmar atribución técnica individual de una clave compartida.

Ante un problema de activación: rollback de la transacción si falla al aplicar. Si ya fue aplicada, detener nuevas altas mediante revocación de revisores y bloqueo controlado de los nuevos RPC, sólo con autorización; conservar solicitudes, auditoría e instituciones aprobadas. No ejecutar DROP ni borrar registros para revertir un alta usada.

## Recuperación: procedimiento preparado, sin copias remotas

El respaldo de PostgreSQL **no incluye automáticamente los bytes de Storage**. Ver [documentación oficial de backups](https://supabase.com/docs/guides/platform/backups) y [restauración con CLI](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore).

### Inventario y captura (requieren autorización nueva)

- Identificar origen piloto y destino aislado distinto. Nunca restaurar sobre `eaegvxxxkvhdukbkydvy`. No iniciar una copia sin autorización del conjunto de datos y destino.
- Fijar ventana de mantenimiento de escrituras o una captura consistente. Registrar versiones PostgreSQL/Auth/Storage, migraciones aplicadas, extensiones y configuración sin secretos. Mantener cron/purga, webhooks, correo y cobros desactivados en destino.
- PostgreSQL: incluir datos de Atena, funciones, políticas, grants, propietarios, constraints, índices y secuencias. Separar configuración/roles administrados de Supabase; no ejecutar un restore genérico de roles sobre un proyecto gestionado. Preparar el export/import según la versión real y la guía oficial; no asumir que un dump CLI por defecto contiene todo Auth.
- Auth: inventariar `auth.users`, identidades y dependencias FK; preservar UUID para que instituciones, operadores y vínculos sigan apuntando a la persona correcta. Credenciales y hashes son sensibles incluso en un backup. No exportarlos a Git. No copiar claves de proyecto, tokens ni sesiones activas al destino. Restaurar identidades mediante el procedimiento compatible con Auth del destino antes de sus dependencias. Exigir un ingreso nuevo y comprobar rechazo de JWT del origen. La configuración de correo/proveedores/redirects se recrea explícitamente, no se presume incluida en la base.
- Storage: enumerar **todos** los buckets/páginas y cada objeto/version, descargar bytes por canal administrativo autorizado, registrar bucket/key/tamaño/hash/metadatos. Capturar los bytes y metadata en la misma ventana. Comprobar ausencia de referencias huérfanas y no declarar un inventario vacío sin consultar realmente Storage. Los documentos que Atena conserve en PostgreSQL se verifican también en el dump; eso no sustituye el inventario de Storage.
- Guardar un manifiesto privado con totales/hashes y relación archivo–registro, configuración no secreta y migraciones. Los nombres de objetos pueden contener datos personales: el manifiesto completo queda dentro del cifrado.

### Cifrado local y custodia

`tool/recovery_bundle.mjs` usa el módulo criptográfico incorporado de Node: AES-256-GCM con nonce aleatorio y scrypt N=65536,r=8,p=1, sal aleatoria de 32 bytes. Autentica cabecera y manifiesto; valida hashes antes de exponer una restauración. No añade dependencias Flutter. Requiere una frase aleatoria fuerte, mínimo 20 caracteres; no pasarla en argumentos, repositorio o logs.

```text
python tool/recovery_bundle.py pack DIRECTORIO_PRIVADO RESPALDO.aes
python tool/recovery_bundle.py restore RESPALDO.aes DIRECTORIO_AISLADO_NUEVO
```

El prompt oculta la frase. Conservarla en un gestor autorizado separado del respaldo. Directorio temporal en volumen cifrado y con ACL restringida; los permisos POSIX de Node no sustituyen ACL/BitLocker en Windows. Mantener el material en claro sólo durante la operación autorizada. El programa no sobrescribe destinos existentes ni borra fuentes.

Límite explícito: esta herramienta carga en memoria hasta 256 MiB; **no** está validada para backups grandes ni streaming. No reemplaza una solución operativa de backups programados. Para datos mayores hay que aprobar y probar una herramienta de cifrado por streaming, conservando autenticación e integridad. No hay export remoto implementado/ejecutado en este bloque.

### Restauración aislada y criterio de aceptación

1. Verificar hash de transporte y descifrar en directorio nuevo. Contraseña incorrecta o alteración → no publicar salida parcial.
2. Preparar un proyecto Supabase aislado compatible, sin correo saliente ni jobs. No reutilizar secretos del origen. Autorizar antes su creación/costos y cada importación remota.
3. Restaurar identidades Auth compatibles, esquema y datos de aplicación en orden de FK. RLS permanece activo, grants revisados antes de habilitar acceso. No restaurar sesiones utilizables.
4. Restaurar objetos de Storage a buckets privados con sus políticas; comparar cada hash, tamaño, metadata y referencia. No sustituir archivos con enlaces públicos.
5. Comparar tablas/fila-hashes, FK, secuencias, funciones, triggers, propietarios, RLS y grants; cotejar historial de migraciones. Probar con JWT **del destino**: propietario autorizado, operador revocado, alumno ajeno, acceso público y documentos privados. Confirmar caducidad de acceso y cron de purga OFF.
6. Abrir el entorno sólo tras PASS de integridad + autorización + Auth/Storage. Un restore parcial es FAIL: mantener destino aislado, conservar el original y la evidencia sin secretos. No completar silenciosamente con datos del origen. Investigar y repetir en otro destino nuevo; cualquier descarte requiere autorización, no se automatiza un borrado remoto.

Ensayo disponible: `tool/rehearse_local_recovery.py --pg-bin RUTA --source atena_disposable_... --encrypted-roundtrip`. Sólo admite localhost y bases ficticias; incluye dump real, cifrado, un objeto Storage ficticio separado, descifrado, restauración en otra base y comparación de integridad/permisos. **No certifica** el servicio Supabase Auth/Storage remoto ni un desastre real.

## Validación y autorizaciones pendientes

La aplicación remota y las pruebas ficticias de alta ya terminaron; no repetirlas. Pendientes: autorizar/publicar el retorno y cambiar Site URL; designar al revisor operativo; autorizar un inventario/copia ficticios y destino aislado para ensayar Supabase completo. No se ejecutaron copias o restauraciones remotas ni pruebas físicas.

### Resultados locales del bloque (10–11 de octubre de 2026)

- Flutter: **472 PASS**, 0 skipped (463 previos + 9 nuevos). Incluye formulario real de solicitud contra servidor HTTP ficticio; signup usa el SDK/PKCE con respuesta ficticia. No se ejecutó signup remoto ni envío de correo.
- PostgreSQL local: **358 PASS** = 263 de la cadena documental/catálogo/sesiones + 48 de solicitudes/concurrencia + 4 de operaciones pendientes + 43 de alta institucional. El nuevo circuito cubre correo sin verificar, duplicados/reintentos, institución existente, rechazo, aprobación/autorización/autoaprobación, propietario, áreas, invitaciones con vencimiento, delegación limitada, revocación, publicación, inscripción y confirmación con cupo compartido.
- Constructor del piloto: **8 PASS**. Cifrado: **2 tests PASS**, con roundtrip, contraseña errónea, alteración, no sobrescritura y rechazo de enlaces.
- Recuperación: **13 comprobaciones PASS**, **40 tablas** restauradas en una nueva base local, incluidas integridad, RLS/grants/funciones, acceso privado denegado y objeto Storage ficticio separado. No equivale a restaurar Auth/Storage como servicios gestionados.
- `flutter analyze`: **76 avisos históricos, 0 nuevos**. Código de salida 1 por esos avisos; no se presenta como análisis sin advertencias.
- Web JavaScript y APK release de evaluación: **PASS**. El sondeo Wasm mantiene advertencias históricas; Wasm no es el artefacto aprobado.
- APK: `build/evaluation/atena-v1-piloto-evaluacion.apk`, SHA-256 `75431a9ee08383e32457d17d20b172615550dea1b195c554844738c6d9166932`. Piloto `eaegvxxxkvhdukbkydvy`, applicationId `org.atena.evaluation.multiuser`, firma de evaluación existente; no distribución pública.
- Escaneo de patrones y contraseñas ficticias conocidas: sin hallazgos en archivos, historial alcanzable y builds; es una comprobación acotada, no una garantía universal de ausencia de secretos. 312 archivos protegidos sin cambios.
- El diagnóstico SQL previamente modificado permanece fuera del commit de este bloque; los cuatro elementos históricos también. No se modificó Supabase ni se hicieron copias remotas, despliegues o pruebas físicas.

### Cierre operativo local (13/10/2026)

Pruebas nuevas del retorno sin red: PKCE/tokens descartados, error vencido/reutilizado, descripción no reflejada, redirección arbitraria ignorada, CSP verificada y fallo de history sin exponer secretos. Pruebas de pantalla del revisor: aprobación con confirmación explícita, rechazo, autoaprobación oculta y permiso revocado durante diálogo sin falso éxito. Los resultados finales de ejecución y builds se registran en `preparacion_evaluacion_v1.md`.

En ese cierre local no se modificó configuración remota ni se designó un revisor. Posteriormente,
el 14/10/2026 se activó y validó el alta familiar con autorización independiente; ver
`alta_familiar_v1.md`. Los revisores de campaña quedaron deshabilitados. El estado y los pasos
operativos vigentes están en `operacion_primer_piloto_v1.md`. Para usuarios reales siguen
pendientes correo/retorno, responsables operativos, recuperación completa y decisiones de
privacidad, representación, custodia y conservación. No se considera producción lista.
