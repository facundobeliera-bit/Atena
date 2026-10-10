# Atena V1 — preparación de evaluación privada

Actualizado: 10/10/2026. Base funcional: `5d6d305`.
Este documento reemplaza el estado «activación pendiente» del informe del 09/10.
No autoriza despliegue, usuarios reales, purga ni nuevas migraciones.
Las pruebas manuales están pospuestas; su única matriz está en
[matriz_validacion_integral_v1.md](matriz_validacion_integral_v1.md).

## Estado comprobado

- Las migraciones 20261009000000, 20261009010000 y 20261009020000 ya fueron aplicadas al piloto. **No repetirlas**.
- Publicación, solicitudes, cupos, módulos y documentos: disponibles para identidades previamente habilitadas. Los ensayos remotos anteriores usan JWT reales.
- Cambio de contraseña: JWT antiguos denegados por Atena; Supabase puede conservar el refresh de la sesión que realiza el cambio, pero el JWT renovado sigue denegado por el corte de Atena.
- Cierre global: primero RPC `atena_revoke_my_sessions`, después Auth global. El primero devuelve normalmente HTTP 204. Refresh anteriores rechazados; access JWT aún firmados no autorizan operaciones privadas.
- Una lectura ya autorizada puede terminar con su snapshot; una escritura autorizada puede terminar antes de la revocación. No se promete retirar información ya entregada.
- Sin realtime: la otra sesión debe actualizar. Sin cola offline: un error no equivale a éxito remoto.
- Purga y cron OFF; plazos definitivos de retención pendientes. Comercial OFF.

## Distribución reproducible del piloto

Constructor: `python tool/build_pilot_evaluation.py --config <JSON_PUBLICO> --flutter <FLUTTER>`.
Sólo acepta estas cuatro entradas públicas, sin campos adicionales:

```json
{
  "ATENA_REMOTE_ENV": "staging",
  "ATENA_MULTIUSER": true,
  "ATENA_SUPABASE_URL": "https://eaegvxxxkvhdukbkydvy.supabase.co",
  "ATENA_SUPABASE_PUBLISHABLE_KEY": "REEMPLAZAR_POR_CLAVE_PUBLICABLE"
}
```

El ejemplo no es ejecutable sin la clave publicable. Guardar la configuración fuera
del repositorio; nunca incluir service_role, tokens Auth, contraseñas o URLs privadas.
El constructor rechaza otro proyecto, producción, modo local, claves privilegiadas y campos extra.
Fija Flutter 3.38.3 / revisión `19074d12f7eaf6a8180cd4036a430c1d76de904e`
(Dart 3.10.1); ejecuta `pub get --enforce-lockfile`, compila con `--no-pub`, verifica
que el lockfile no cambie y registra versiones, fuentes, certificado y hashes.
También fuerza los flags Android multiusuario=1 y demo=0, evitando heredar un entorno incorrecto.

Salidas ignoradas por Git:

- `build/evaluation/atena-v1-piloto-evaluacion.apk`.
- `build/evaluation/atena-v1-piloto-web.zip` (contiene `build/web`, no se publica).
- `build/evaluation/manifest.json` (HEAD, cambios tracked, hash de fuentes, lockfile,
  configuración pública, archivos web, APK, ZIP, Java y herramientas Android).

Identidad Android: `org.atena.evaluation.multiuser`, etiqueta «Atena Multiusuario».
El acceso muestra «Sólo cuentas piloto habilitadas». Separado de la demo municipal
`org.atena.demo.municipio`. El identificador genérico `com.example.flutter_application_1`
NO es un identificador de producción aprobado. La configuración Dart rechaza piloto como producción.
Android usa la firma de desarrollo existente. Su certificado debe conservarse para
actualizaciones privadas sin pérdida de datos; nunca desinstalar para resolver una firma distinta.
No se creó ni se cambió un keystore. Identificador, firma, dominio y distribución de
producción siguen pendientes de decisión. No publicar este APK en Play Store.

Reproducibilidad significa entradas y herramientas registradas; no se promete igualdad
binaria entre máquinas con distintos certificados, ZIP timestamps o herramientas.
Para reproducir en otra computadora, usar la revisión indicada, lockfile versionado,
SDK/Java del manifiesto y el mismo certificado privado protegido. No ejecutar `flutter clean`
sobre los artefactos reservados. El escaneo de secretos no sustituye una auditoría integral.

## Alta institucional: bloqueo real, no PASS simulado

| Paso | Evidencia y estado |
| --- | --- |
| Registro local, plan, propietario/perfil, logout e ingreso | Tests `institution_registration_android_flow_test.dart`: PASS; también recuperación legítima del registro parcial y rechazo de otra credencial. Sólo local. |
| Registro en modo multiusuario | BLOQUEADO por diseño: botones de registro y recuperación deshabilitados; no hay `signUp` institucional en `MultiuserSession`. Dos tests `remote_onboarding_contract_test.dart` verifican esa separación. |
| Identidad remota | `atena_authenticated_context` exige Auth + operador + vínculo verificado + área/asignación activa; una cuenta sin ellos devuelve listas vacías. Coincidir email/ID local no concede acceso. |
| Asignación de operador/área | No existe onboarding remoto autónomo para dar esas autorizaciones. Configurar operadores locales no crea permisos remotos. |
| Crear borrador/publicar/retirar | PASS para operador previamente habilitado; `catalogWorkspace`/`editCatalog` y SQL verifican capacidades y contexto. PARCIAL como proceso integral de una institución nueva. |
| Solicitudes/confirmación | PASS con solicitante y operador previamente habilitados; no habilita instituciones nuevas por sí mismo. |
| Alumno/familia | Requiere vínculo de perfil autorizado. El piloto no incorpora un alta autónoma de tutores ni acreditación de representación de menores. |

**Modificación mínima propuesta, no implementada:** flujo de invitación/alta verificada
server-side que, tras prueba de titularidad aprobada, cree en una transacción institución,
operador propietario individual, vínculo verificado y primera área/asignación con capacidades
mínimas; unicidad e idempotencia. Los demás operadores aceptan invitaciones con su propio
Auth; nunca heredan la contraseña del propietario. Requiere decidir quién verifica titularidad,
cómo se acredita, y autorizar el esquema/RPC/RLS y UI mínimos. No abrir escrituras directas
ni convertir datos locales o una coincidencia de correo en prueba de propiedad.

## Respaldo y recuperación

Responsable pendiente de designación: administrador técnico del piloto. El propietario
aprueba destino cifrado, custodios, frecuencia, conservación y RPO/RTO antes de usar datos reales.
No se activaron servicios pagos ni un trabajo de respaldo automático. No se presupone
que el plan gratuito tenga restauraciones gestionadas disponibles.

1. Inventariar proyecto, versión, ledger, funciones/RLS/grants, vínculos, pools y recuentos.
2. Para una copia real futura: exportar usando el procedimiento oficial de Supabase en un
   destino cifrado fuera de Git; separar roles/esquema/datos y cambios personalizados de Auth.
   Incluir `atena_private` y BYTEA documental. Un backup sólo de `public` es insuficiente.
3. Auth: conservar relaciones UUID, identidades y el trigger `atena_sensitive_auth_change`.
   Supabase excluye modificaciones de esquemas gestionados del dump ordinario de estructura;
   registrar el delta de Auth para restaurarlo de manera compatible, no recrear todo Auth a ciegas.
   Los secretos externos de Auth/proveedor son una custodia separada y nunca parte del cliente.
4. No copiar sesiones activas para reabrir accesos revocados. Antes de activar una recuperación
   real, diseñar y autorizar reconciliación de sesiones/cortes y login nuevo. No ejecutar revocaciones
   masivas sobre el piloto como parte de este ensayo.
5. Restaurar primero en un destino aislado, nunca encima del proyecto activo. Verificar integridad,
   permisos negativos, cupos efectivos y lectura documental; sólo después decidir con autorización
   un cambio de endpoint. Sin `DROP`, `--clean`, borrado de datos ni rollback destructivo en remoto.
6. Comparar hashes/recuentos, claves foráneas, índices, constraints, trigger, funciones,
   políticas y privilegios. Confirmar purga OFF y comercial OFF. Si difieren, no habilitar clientes.

Ensayo automatizado disponible:

```
python tool/rehearse_local_recovery.py --pg-bin <BIN_POSTGRES17> --source <atena_disposable_...>
```

Sólo admite localhost, usuario de pruebas y base `atena_disposable_*`; crea otra base,
no borra ninguna. Ejecuta pg_dump/pg_restore reales y compara todos los datos, RLS,
privilegios, funciones, índices, secuencias, constraints y triggers. Prueba catálogo anónimo, denegación privada
anónima y purga OFF. Salidas: `build/recovery/result.json` y dump ficticio ignorado por Git.
ACL NULL y ACL por defecto explícita se normalizan según PostgreSQL, sin quitar comprobaciones.
Esto prueba restauración de fixtures PostgreSQL, **no recuperación completa de Supabase Auth**.
No hay backup remoto nuevo ni ensayo de desastre remoto en esta unidad.

Fuentes: [Backups Supabase](https://supabase.com/docs/guides/platform/backups),
[restauración con CLI y deltas Auth](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore).
Los archivos actuales viven como BYTEA; si se adopta Storage, habrá que respaldar también
sus objetos: las copias de base de datos no contienen esos objetos.

## Fallos de conectividad y errores operativos

| Situación | Procedimiento seguro |
| --- | --- |
| Timeout al guardar/publicar/solicitar | No afirmar éxito; mantener la operación/idempotency key durante el reintento. Reconsultar estado remoto antes de crear otra operación. Después de reiniciar, no asumir que una operación incierta falló. |
| Confirmación incierta | Leer solicitud y ocupación efectiva; repetir la misma decisión sólo mediante RPC existente. Nunca corregir contadores manualmente. |
| Versión obsoleta/conflicto | Volver a leer borrador/versiones y revisar diferencias; no sobreescribir automáticamente. |
| Offline | Mostrar error; no guardar en modo local como sustituto remoto. Recuperada la conexión, actualizar antes de decidir. |
| Sesión revocada | Ante `42501` explícito de sesión, cerrar Auth local y rutas privadas; login nuevo. Otro error de permisos no es motivo de logout global. |
| Área sin permisos | No cambiar institución/operador desde IDs del cliente; consultar asignación administrativa autorizada. |
| Documento vencido | Rechazar apertura. No extender acceso, copiar contenido o activar purga automáticamente. |
| Datos inesperados | Detener sólo la operación afectada, conservar evidencia mínima, comparar con respaldo/integridad; no resetear SharedPreferences ni borrar tablas. |

Errores: registrar fecha UTC, versión del APK/web, módulo, operación, status HTTP,
SQLSTATE y un identificador de correlación opaco. No registrar Authorization, JWT,
refresh, contraseña, email/documento, payload de solicitudes, notas, archivos, URLs firmadas
ni respuestas completas. Usar sólo fixtures al reproducir; cualquier log legado de desarrollo
puede contener IDs: no adjuntarlo sin revisión. No se añadió telemetría ni un servicio externo.

## Revocar un operador

Procedimiento administrativo preparado, no ejecutado en esta unidad:
identificar con evidencia institución + operador + área/asignación; registrar motivo y
alcance; obtener autorización; desactivar sólo esa asignación/capacidad en una transacción
controlada. Una baja de persona puede requerir revocar vínculo/operador y sesiones;
no reemplazar un alcance por otro ni revocar la cuenta propietaria por error.
Verificar con JWT anterior que el siguiente RPC y las lecturas RLS rechazan el acceso,
y comprobar otra área/operador no afectado. No borrar historial ni atribución de operaciones.
Rehabilitar acceso no debe revivir sesiones cortadas: exigir autenticación nueva cuando corresponda.
No hay interfaz administrativa remota autónoma de alta/baja de operadores validada;
es una dependencia explícita, no una función declarada lista para usuarios sin soporte técnico.

## Pendientes que requieren decisión/autorización

- Onboarding remoto verificado de instituciones, operadores y perfiles solicitantes.
- Respaldo remoto cifrado, custodios, periodicidad, RPO/RTO y ensayo de recuperación aislado.
- Política de privacidad, representación de menores, conservación documental y operación del servicio antes de datos reales.
- Identidad/firma/distribución de producción sólo si se decide publicar; fuera del piloto actual.
- Validación integral futura: matriz preparada, ninguna fila ejecutada manualmente en este sprint.

## Resultado de esta preparación

- 463 tests Flutter PASS (461 anteriores + 2 contratos de alta remota), sin omitidos.
- 8 pruebas del constructor PASS: entorno, proyecto, modo remoto, tipo booleano y claves.
- Recuperación local PASS: 35 tablas, 11 comparaciones/comprobaciones, 4,63 segundos en este equipo.
  Es una medición del fixture pequeño, no un compromiso RTO del servicio real.
- Referencia SQL anterior: 315 PASS; no se modificó SQL productivo ni se repitieron las campañas remotas.
- `flutter analyze`: 76 avisos históricos, ningún aviso nuevo en el test agregado; exit 1 por la línea base.
- Builds Android release y web JavaScript PASS. WASM no validado (avisos de dependencias preexistentes).
- APK SHA256: `ab4f81c3233219fb0aa13fd9297ee4e325b91ccd502e02d4e3f7d1ec06814722`.
  Coincide con el APK funcional previo: no hubo cambios productivos. El manifiesto registra
  `5d6d305` como base compilada; el commit de preparación sólo contiene scripts, tests y documentación.
- Firma Android verificada; Java 21.0.8 y Build Tools 36.1.0. Sin actualización de dependencias.
- No se ejecutaron pruebas físicas/manuales, deployment, cambios remotos ni activación de purga/comercial.
