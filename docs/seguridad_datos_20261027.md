# Seguridad técnica y soporte de protección de datos — 27/10/2026

Cierre de verificaciones: 29/10/2026.

Alcance local y focalizado. Sin contactos/cambios Supabase, distribución, pruebas físicas,
designación de revisores, recuperación de contraseña ni aceptación legal obligatoria.
El APK de evaluación 1.0.0+2 del 23/10 conserva su hash; no contiene estas correcciones.

## Evidencia y cambios

| Componente | Estado y alcance demostrado |
|---|---|
| Sesión Android | CORREGIDO. La inicialización usaba `SharedPreferencesLocalStorage` por defecto (supabase_flutter 2.14.2). Ahora usa `flutter_secure_storage` 10.3.4 y su cifrado Android respaldado por KeyStore. No se implementó criptografía propia. |
| Migración y logout | CORREGIDO. Copia al almacén seguro, verifica lectura y elimina sólo la clave Auth anterior. La copia segura prevalece ante residuos de una migración interrumpida. Error de cifrado conserva el original y no inicia sesión desde un fallback inseguro. Escrituras serializadas y marca vacía de cierre impiden resurrección tras interrupción. El logout espera además la eliminación segura. PKCE se migra y elimina junto con la sesión; recuperación sigue OFF. |
| Backup Android | CORREGIDO. Se excluyen datos privados de cloud backup y transferencia automática. No elimina respaldos anteriores ni datos actuales. Cambiar de teléfono requerirá un procedimiento de recuperación explícito; no se promete restaurar claves KeyStore en otro dispositivo. |
| Credenciales locales | VALIDADO por evidencia P1-B/P1-D existente y revisión de los puntos afectados: PBKDF2-SHA256, sal individual, 600.000 iteraciones y migración legítima permanecen intactos. No se repitió la campaña criptográfica. Credenciales legacy aún no migradas no quedan certificadas para usuarios reales. |
| Documentos remotos | CORREGIDO el rechazo de respuesta tardía tras cambiar el token aun con el mismo usuario. El acceso privado existente devuelve bytes por RPC autorizado, sin URL pública permanente ni copia nueva en SharedPreferences. Se reutiliza la evidencia RLS previa; no se volvió a ejecutar contra el servidor. |
| Vista y exportación | CORREGIDO. La vista remota se cierra tras cambio de sesión o salida de primer plano; exige reabrir mediante autorización vigente. Compartir/imprimir revalida el acceso y la sesión original. Se mantienen esas acciones; los errores del callback PDF se sanitizan antes de que la biblioteca los registre. No se garantiza eliminación forense de memoria, capturas del SO ni copias exportadas voluntariamente. |
| Errores y logs | CORREGIDO. Pantallas/acciones documentales ya no interpolan excepciones externas. Los diagnósticos de cuenta/sesión emiten flags, no IDs, DNI, valores crudos ni etiquetas arbitrarias. Se desactiva el volcado de logs de Supabase incluso en builds debug. |
| Aceptación legal | BLOQUEADO para activación. Candidato SQL y pruebas locales preparados; requiere PostgreSQL sano, textos aprobados y autorización remota. No hay texto jurídico definitivo ni checkbox, aceptación automática o bloqueo del piloto. |
| Recuperación integral | BLOQUEADO para demostrar el servicio completo. Verificador offline adicional probado con fixtures; no se ejecutó ninguna restauración ni copia del piloto. |

Fuentes del mecanismo de almacenamiento: [supabase_flutter](https://pub.dev/packages/supabase_flutter),
[flutter_secure_storage 10.3.4](https://pub.dev/packages/flutter_secure_storage/versions/10.3.4).
Se contrastó con el SDK instalado. Tests del almacén simulan el canal de plataforma:
no son una prueba física de KeyStore, actualización o restauración Android.

## Infraestructura legal preparada, no aplicada

`supabase/candidates/20261027000000_legal_receipts_review_only.sql` depende de
`auth.users`, `auth.uid()`, `require_current_session[_read]` y
`onboarding_verified_email()` ya definidos en las candidatas anteriores.

- Tres tablas privadas con RLS: control OFF, versiones de documentos, recibos.
- Documento identificado por clave, versión, revisión ordenada, propósito,
  audiencia, vigencia, aprobación y hash calculado en servidor. Texto inmutable;
  revisiones nuevas no alteran el contenido aceptado anteriormente.
- Diferencia aceptación contractual, constancia informativa y consentimiento
  específico. Retirar consentimiento registra otro evento, nunca borra el anterior.
  Esto no ejecuta automáticamente borrado, purga ni tratamientos jurídicos.
- RPC de lectura devuelve versiones vigentes y recibos **sólo de auth.uid()**.
  RPC de registro exige sesión vigente, correo verificado, acción explícita,
  versión/hash correctos, operación idempotente y fecha del servidor.
- Ningún parámetro permite seleccionar otro aceptante, menor o institución.
  Aceptar un documento de audiencia institucional es un acto personal; **no acredita
  representación legal ni vincula jurídicamente a terceros**. El vínculo familiar
  existente tampoco equivale a consentimiento universal.
- No cambia roles de usuarios ni revisores, ni amplía acceso a documentos privados.
  Los recibos y textos no permiten UPDATE/DELETE de historia; nuevas versiones
  aparecen en el RPC y requieren un acto nuevo si una política futura lo establece.
- No se integra todavía una pantalla obligatoria: no existen textos aprobados.
  No hay casillas premarcadas ni activación de enforcement en el cliente.

Prueba preparada: `tool/test_legal_receipts.py --psql <ruta> --port <puerto-local>`.
Usa únicamente localhost y una nueva base `atena_disposable_legal_*`; no elimina la
base al finalizar. Cubre actor, fecha, idempotencia, aislamiento, vigencia,
hash, versiones, RLS, inmutabilidad y revocación. Los guards/Auth son fixtures
explícitos: no sustituye validación de JWT real ni integración con todas las migraciones.

**No ejecutada**: no hay servidor en los puertos locales conocidos y falta
`share/postgres.bki` en las instalaciones temporales existentes. No se reparó ni
se instaló un runtime adicional. No presentar esta candidata como lista para aplicar
hasta ejecutar este test y verificarla con las dependencias reales en una base aislada.

## Preparación del ensayo de recuperación

Se conserva `recovery_bundle.mjs` (cifrado autenticado) y el ensayo PostgreSQL existente.
Se agrega `verify_recovery_inventory.py`, sin red ni escrituras: compara inventarios
antes/después, fingerprints de filas/RLS/grants/funciones y dependencias Auth,
perfiles/inscripciones/documentos; comprueba bytes reales de los objetos separados,
propiedad y privacidad. Rechaza archivos faltantes, hashes distintos, rutas inseguras,
políticas distintas y destino igual al origen. Nunca declara `integral_restore_validated`.

Formato de ejemplo ficticio en `tool/test_verify_recovery_inventory.py`.
Los inventarios reales del ensayo deben extraerse del stack local, no rellenarse
manualmente como prueba de éxito. Los hashes de configuración deben comparar sólo
valores semánticos no secretos; claves nuevas y URLs del destino se validan aparte.

Ejecución offline prevista:
```
python tool/verify_recovery_inventory.py --before <inventario-origen.json> --after <inventario-restaurado.json> --source-objects <objetos-origen> --restored-objects <objetos-restaurados>
```

Recurso faltante: stack aislado sano PostgreSQL + Supabase Auth compatible + Storage,
sin conexión al piloto, correo saliente ni cron. Necesita preparación/autorización
separada, no infraestructura paga. Orden: fixtures locales → inventario → dump y bytes
Storage separados → bundle cifrado → destino vacío con claves propias → restore →
comparación → login real del Auth aislado y pruebas de acceso/denegación/expiración.
Una restauración parcial permanece cerrada; no se modifica el origen. Ningún script
nuevo recoge credenciales ni restaura el piloto.

## Validación y límites

- 56 pruebas Flutter focalizadas PASS, incluidas 13 nuevas de este bloque.
- 13 pruebas Python del verificador offline PASS; sintaxis Python del harness SQL PASS.
- Análisis de 15 archivos Dart afectados sin incidencias; no suite general repetida.
- Android release y web JavaScript: PASS. Compilaciones internas, no distribuidas.
  Web mantiene avisos de dependencias incompatibles con el ensayo Wasm y de la
  opción histórica `synthetic-package`; no se solicitó ni publicó un build Wasm.
- `git diff --check`: PASS.
- SQL legal: ejecución pendiente, sin afirmación de PASS PostgreSQL.
- 312 archivos protegidos y APK entregado conservados mediante SHA-256.

Antes de datos reales siguen pendientes: validación nativa del almacenamiento y de la
actualización Android, decisión sobre persistencia web (el SDK aún usa localStorage,
accesible al JavaScript del origen), tratamiento de datos/documentos del modo local
legacy y copias exportadas, restauración integral y textos/políticas jurídicos aprobados.
No se sustituyó la persistencia web por memoria porque cambiaría el contrato de
reconstrucción ya aprobado; requiere una decisión específica y sus pruebas.
Las copias antiguas de tokens en respaldos previos no se revocan con un cambio local.

El piloto ficticio existente no se bloquea. Recuperación de contraseñas, revisores,
retención/purga y servidor remoto permanecen sin cambios. La compilación de comprobación
no implica distribución ni aprobación para producción.
