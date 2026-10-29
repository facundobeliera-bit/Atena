# Candidata de evaluación con seguridad — 29/10/2026

Alcance: incorporar `7b8b6b859b53d90ab125dfa3e1f7d5213a381641` a un APK
privado de evaluación. Sin escrituras remotas, instalación, distribución, migraciones
ni cambios de funcionalidad. Se conservan los 312 archivos protegidos y el APK +2.

## Sesiones y documentos

Se agregaron tres regresiones del almacén seguro: fallo de lectura sin fallback a
SharedPreferences, fallo de logout comunicado y reintento que limpia sesión/PKCE,
y cambio de cuenta persistido tras reconstruir el almacén. Las pruebas usan el canal
de plataforma simulado: **no demuestran KeyStore en un teléfono**. Se conservan las
pruebas anteriores de migración, escritura fallida, lectura de verificación, marca
de cierre, concurrencia, respuestas tardías y ocultamiento al cambiar de identidad.
No se encontraron defectos funcionales adicionales que justificaran cambiar Auth.

Resultado: 61 pruebas Flutter focalizadas PASS (incluye tres nuevas), sin llamadas
al piloto. Cubre almacenamiento, documentos, navegación de sesión e inscripción,
confirmación, baja, reintentos y cupos mediante HTTP simulado. No es una repetición
de la campaña JWT remota ni una prueba física. Las 13 pruebas offline de recuperación
conservan su evidencia anterior y no se volvieron a ejecutar.

Web conserva `supabase_flutter 2.14.2` con `local_storage_web.dart`: la sesión se
guarda en localStorage y se elimina al salir. No contiene una contraseña, pero sí
credenciales de sesión accesibles al JavaScript del origen. No equivale a KeyStore
ni protege frente a XSS. Cambiar a memoria rompe persistencia/F5; cookies HttpOnly
exigen una frontera de servidor que no existe en este bloque. No se introdujo ninguna
de estas alternativas silenciosamente. Sigue siendo una limitación para datos reales.

Inspección de las bibliotecas fijadas y del código, sin leer archivos del usuario:

| Archivo/operación | Evidencia y límite |
|---|---|
| Documentos multiusuario | Bytes recibidos mediante RPC autorizado, sin persistencia documental local nueva. Vista y exportación comprueban identidad/token; PDF revalida antes de imprimir/compartir. |
| Imagen compartida (`share_plus 7.2.2`) | Crea un origen temporal con UUID en caché y copia a `cache/share_plus`. Provider no exportado; comparte mediante permisos URI. El origen puede permanecer hasta limpieza del SO; no se garantiza limpieza inmediata. |
| PDF compartido (`printing 5.14.2`) | `cache/share/documento-atena.pdf`, provider no exportado y permisos URI. `deleteOnExit` no demuestra borrado tras retorno de la acción. |
| Exportaciones | El receptor puede conservar la copia; logout no puede revocarla. Las dependencias conceden permisos de URI de lectura/escritura: no se presentan como enlaces privados revocables de Supabase. |
| Modo local histórico | Documentos y datos continúan en su persistencia local previa. No se borran ni se migran masivamente. No queda certificado como almacenamiento cifrado para datos reales. |

Los archivos de caché anteriores pertenecen al espacio privado de la aplicación,
no a una ruta pública de Storage. No se prueba su exposición entre aplicaciones
arbitrarias. Tampoco se declara limpieza efectiva sin evidencia nativa. Se necesita
un ciclo de vida explícito para exportaciones antes de datos reales; borrar al cerrar
el selector puede interrumpir al destinatario. No se eliminaron copias existentes ni
se deshabilitó la función de evaluación. Los logs intervenidos usan mensajes neutrales.

## Aceptación legal: bloqueo localizado

En las instalaciones temporales disponibles `atena-family-runtime/pgsql` y
`atena-pg17-sprint/pgsql` existen ejecutables pero falta `share/postgres.bki`.
No hay servicio PostgreSQL instalado ni otra copia de ese archivo/archivo comprimido
en los directorios temporales examinados. No puede inicializarse un cluster nuevo
fiable con ese material. No se mezclaron versiones ni se alteró un cluster anterior.

El candidato `20261027000000_legal_receipts_review_only.sql` y
`tool/test_legal_receipts.py` se conservan sin cambios. SQL **sin ejecutar**; no hay
PASS PostgreSQL ni autorización implícita para aplicarlo. Recurso mínimo: distribución
PostgreSQL completa de la versión compatible, instancia desechable sólo localhost y
roles locales de prueba. No requiere por sí mismo Docker/WSL, ni se instaló software.

## Inventario ejecutable para recuperación aislada

Se conservan las 13 pruebas aprobadas del verificador; no se repiten. Antes de un
ensayo integral se necesitan los siguientes artefactos de **un origen ficticio local**,
no del piloto. El siguiente control sólo enumera disponibilidad: no exporta, descifra,
restaura ni imprime contenidos. No es una prueba de recuperación.

```powershell
$bundleRoot = 'build/recovery/isolated-fixtures'
$required = [ordered]@{
  'database.dump' = 'Datos y esquemas public/atena_private/auth/storage, con dependencias'
  'database-schema.sql' = 'Funciones, triggers, RLS, grants, índices, secuencias y roles'
  'auth-config.redacted.json' = 'Versión Auth, configuración sin secretos y correo saliente OFF'
  'storage-config.redacted.json' = 'Versión Storage, buckets privados y backend de objetos'
  'storage-inventory.json' = 'Nombre, tamaño, SHA-256, propietario y bucket de cada objeto'
  'storage-objects' = 'Bytes reales de objetos privados; no sólo filas storage.objects'
  'migrations' = 'SQL exacto ordenado y registro del historial aplicado'
  'source-inventory.json' = 'Huellas de BD y referencias Auth/perfiles/documentos/inscripciones'
  'runtime-versions.json' = 'Versiones/digests fijados y orden de arranque del destino aislado'
  'restore-plan.md' = 'Orden, credenciales nuevas fuera del bundle y cierre ante fallo parcial'
}
$required.GetEnumerator() | ForEach-Object {
  [pscustomobject]@{Artefacto=$_.Key; Disponible=(Test-Path -LiteralPath (Join-Path $bundleRoot $_.Key)); Necesario=$_.Value}
}
```

El dump Auth contiene material sensible incluso siendo ficticio: restringir acceso y
cifrar con `tool/recovery_bundle.py pack`, frase por entrada oculta y fuera de Git.
No imprimir hashes de contraseñas ni restaurar sesiones vigentes del origen.
Preparar claves nuevas para el destino mediante su mecanismo de secretos, nunca en
los JSON anteriores. El bundle existente admite hasta 256 MiB; no asumir capacidad mayor.

Una vez autorizado y disponible un stack aislado sano PostgreSQL + Auth + Storage:
restaurar en destino distinto, generar `restored-inventory.json` desde el servicio y
comparar con `tool/verify_recovery_inventory.py --before ... --after ...
--source-objects ... --restored-objects ...`. El resultado de ese script conserva
`integral_restore_validated=false`: faltan login Auth real, JWT nuevos, autorización,
revocación, expiración Storage y consistencia conjunta. Si falla algo, mantener destino
cerrado y origen intacto. No habilitar correo, cron, purga ni acceso público.

Dependencia pendiente: runtime completo de esos tres servicios y dos entornos
ficticios independientes; preparar sólo PostgreSQL no cierra la recuperación integral.
No se contratan servicios ni se presume un proyecto remoto adicional gratuito.

## Actualización privada de evaluación

APK previsto `build/evaluation/2026-10-29-seguridad/atena-v1-seguridad-evaluacion.apk`,
versión 1.0.0+3, aplicación `org.atena.evaluation.multiuser`. El manifiesto contiguo
registra commit, fecha, firma, herramientas, opciones, fuentes y SHA-256 verificadas.
No se considera generado hasta que build e inspección terminen.

Configuración: proyecto piloto `eaegvxxxkvhdukbkydvy`, bajas ON; rectificaciones y
recuperación de contraseña OFF. Misma firma de evaluación que +2, no firma de producción.
No se modifica el APK histórico ni se instala automáticamente.

Cuando el propietario decida probar: copiar el nuevo APK al teléfono e instalar
**como actualización de Atena Multiusuario**, sin desinstalar ni borrar datos.
Si Android rechaza la firma/actualización, detenerse y conservar la instalación.
Comprobar después acceso/reinicio/logout con cuentas ficticias; la migración nativa
no se declara verificada hasta ese momento. Copias anteriores de tokens no quedan
revocadas por compilar este cambio.
