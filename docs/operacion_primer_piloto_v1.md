# Atena V1 — operación del primer piloto

Fecha: 14/10/2026. Proyecto exclusivo: `eaegvxxxkvhdukbkydvy`, región `sa-east-1`.
Este documento es una propuesta operativa; no autoriza publicación, cambios remotos,
uso de datos reales ni eliminación. No sustituye asesoramiento jurídico.
No cambia el funcionamiento de Flutter ni crea nuevos módulos.

## Estado y acciones que faltan

Alta institucional y familiar, operadores, áreas, publicación, inscripciones y cupos
fueron validados con JWT reales. La campaña familiar cerró con 96 pruebas remotas,
34 controles de activación y 14 posteriores. La nueva lectura del 14/10 confirma esos
14 controles: 66 funciones iguales al esquema probado, filas históricas de 38 tablas
y 15 usuarios anteriores intactos, comercial y purga OFF. No repetir las migraciones.

Bloqueos operativos: correo/retorno, designación de revisores permanentes, recuperación
integral de servicios y decisiones de privacidad. No son motivos para rehacer módulos.
La única matriz de evaluación posterior sigue siendo
[matriz_validacion_integral_v1.md](matriz_validacion_integral_v1.md), sin marcar pruebas manuales PASS.

## Correo y retorno: plan exacto, todavía sin ejecutar

Lectura remota: `site_url=http://localhost:3000`, lista de redirects vacía,
`mailer_autoconfirm=false`, límite 2 mensajes/hora, SMTP propio sin configurar.
El alojamiento existente responde 200 en
`https://atena-staging.facundobeliera.workers.dev/`; `/auth/return.html` devuelve 404.
No hace falta inventar un dominio para el retorno. No se comprobó una cuota o contrato
de hosting nuevo; sólo se verificó que el Worker existente es accesible.

1. Autorizar actualización del Worker existente con el build revisado. **El comando
   reemplaza el conjunto completo de Static Assets**, no agrega un archivo suelto.
   No desplegar una carpeta que contenga sólo el retorno: reemplazaría los assets de la app.
   Antes de ejecutarlo, comparar versión/configuración remota y obtener autorización
   expresa para ese build completo. No crear Worker, rutas ni fallback SPA adicionales.

   ```text
   pnpm dlx wrangler@4.131.2 deploy --assets=build/web --name=atena-staging --compatibility-date=2026-09-15
   ```

2. Verificar 200 HTTPS en `/auth/return.html`, contenido igual al build, CSP y ausencia
   de recursos externos. Hacerlo sin tokens en URL ni capturas de enlaces reales.
3. Sólo después, autorizar este cambio de Auth en el proyecto piloto:

   ```json
   {"site_url":"https://atena-staging.facundobeliera.workers.dev/auth/return.html"}
   ```

   Mantener `mailer_autoconfirm=false`, lista de redirects sin comodines y el resto de
   campos sin cambios. No activar aprobación automática ni cambiar passwords.
4. Autorizar proveedor SMTP/dominio, cargar la credencial directamente en configuración
   protegida de Supabase y verificar envío/confirmación con una cuenta ficticia autorizada.
   Si falla, detener nuevos envíos y conservar el estado; no volver a localhost como solución.

La página existente borra fragmento/query inmediatamente, no persiste ni intercambia tokens,
no usa SDK, red o logs y no declara confirmación por un parámetro del cliente. El estado real
se consulta al ingresar. Error vencido/reutilizado se muestra sin reflejar texto no confiable.
**No implementa restablecimiento de contraseña**: un retorno `type=recovery` también descarta
credenciales. Los flujos informativos no son una recuperación remota autónoma. Antes de prometer
recuperación operativa hay que autorizar y validar un circuito legítimo separado; no habilitar
el reset histórico inseguro. Las pruebas de descarte no cuentan como reset exitoso.

### SMTP recomendado para evaluación del propietario

Precios/límites consultados el 14/10/2026; pueden cambiar. No se contrató ni activó proveedor.

| Opción | Plan gratuito publicado | Requisitos y decisión |
| --- | --- | --- |
| Resend, recomendado para piloto pequeño | 3.000/mes, máximo 100/día | Dominio propio verificado, DNS SPF/DKIM y remitente autorizado. SMTP `smtp.resend.com`, puerto 465/TLS, usuario `resend`; password es una API key secreta cargada sólo en Supabase. |
| Brevo, alternativa | 300/día, sin acumulación | Cuenta habilitada para transaccional, dominio/remitente autenticados y credencial SMTP del proveedor. Confirmar admisión/límites de cuenta antes de elegirlo. |

No consta un dominio de correo bajo control del propietario. Gmail y `workers.dev` no son
dominios que podamos verificar por cuenta propia. Un plan SMTP gratuito no aporta un dominio
propio gratuito ni garantiza entrega. No comprar dominio sin autorización.
Preparar `smtp_host`, `smtp_port`, `smtp_user`, `smtp_admin_email`, `smtp_sender_name` y
`smtp_pass`; los primeros dependen del dominio aprobado y el último nunca va en Git ni Flutter.
Mantener inicialmente el límite propio de Supabase de SMTP personalizado (30/h según su guía)
y ajustar sólo con autorización, sin superar el presupuesto diario/mensual. No activar pagos.
Un rate limit de Supabase no sustituye el límite del proveedor; ante cuota agotada parar altas.

Fuentes: [Supabase SMTP](https://supabase.com/docs/guides/auth/auth-smtp),
[Resend precios](https://resend.com/pricing), [Resend SMTP](https://resend.com/docs/send-with-smtp),
[Brevo gratuito](https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan).

## Revisores: una designación controlada y operación cotidiana desde Atena

Actualmente hay **0 revisores institucionales y 0 familiares activos**; los de campaña fueron
deshabilitados. El propietario debe elegir personas con cuentas verificadas y autorización
documentada. Registro ordinario no concede revisión. No compartir passwords ni cuentas.

El custodio técnico designado prepara sin escribir:

```text
python tool/onboarding_admin.py --reviewer-user UUID_INSTITUCIONAL
python tool/onboarding_admin.py --scope family --reviewer-user UUID_FAMILIAR
```

`UUID_*` son marcadores, no ejecutar literalmente. Tras comprobar titularidad y autorización,
la misma herramienta admite `--execute-authorized-pilot eaegvxxxkvhdukbkydvy`; solicita la
credencial administrativa de forma oculta. **No ejecutado en este cierre**. No entregar esa
credencial al revisor ni incorporarla al cliente. Registrar externamente quién autorizó y
ejecutó la designación: una clave compartida no prueba la identidad humana del administrador.

| Responsable | Ruta cotidiana | Acción y evidencia |
| --- | --- | --- |
| Revisor institucional | Cuenta → Incorporación y administración institucional | Pendientes → revisar representación externamente → aprobar/rechazar con referencia no sensible. Auditoría `onboarding_audit`. |
| Revisor familiar | Cuenta → Mis perfiles y vínculos familiares | Revisar identidad/edad/responsabilidad acreditada → aprobar/rechazar. Puede revocar un vínculo ajeno autorizado; historial preservado. Auditoría `family_audit`. |
| Propietario institucional | Administración institucional | Invitar con área/capacidades limitadas, administrar áreas y revocar operadores; no designa revisores. |

No hay autoaprobación. No se considera identidad verificada por coincidencia de email/nombre.
Las decisiones se comprueban en servidor; un permiso revocado invalida la siguiente operación
aunque haya un diálogo abierto. Un snapshot previamente entregado no se puede retirar.
Reemplazo de revisor: designar nuevo UUID confirmado, validar acceso, deshabilitar anterior
con `--disable` y el mismo scope. Ante incidente, revocar primero al anterior. Cada ejecución
remota requiere autorización. No editar tablas ni conceder un rol global a usuarios ordinarios.

## Incidente del retorno: contenido, con límite de verificación explícito

Alcance: una cuenta ficticia nueva, sin vínculos de solicitante ni asignaciones privadas.
Un diagnóstico del navegador expuso access token y refresh token. No se reproducen aquí,
no se reutilizan para pruebas y no se han incluido en el código o build.
El 14/10 se observó `disabled=true` en Atena, corte de sesiones vigente y bloqueo Auth hasta
**15/10/2026 18:03:56 UTC (15:03:56 Argentina)**. Aún existe una fila de sesión Auth.
Por tanto, **no se declara que los refresh tokens fueron eliminados de GoTrue** ni que la
contraseña fue cambiada. El access token expuesto ya superó su expiración de una hora;
ello no prueba que el refresh haya caducado.

El bloqueo de Atena no tiene vencimiento: incluso una sesión nueva posterior al corte es
rechazada mientras `disabled=true`. El test local `test_containment_expiry.py` reproduce
ban vencido, sesión antigua/nueva, lectura de contexto/familia y revocación posterior:
6 controles PASS (incluye sesión válida antes de contener), transacción revertida.
Es prueba del guard SQL, no de GoTrue real.
La revisión READ-ONLY confirma que el guard remoto coincide con el probado localmente.
**Prueba remota posterior a las 24 horas: pendiente**; no anticipar su PASS.
Aunque Auth permita login/refresh tras el ban, eso no devuelve acceso privado en Atena.
No reactivar esta cuenta ni cambiar su estado sin nueva autorización.

Las salidas posteriores contienen sólo estados/fechas/recuentos, sin JWT, emails completos,
passwords ni URLs de retorno con parámetros. No se garantiza la eliminación del diagnóstico
ya expuesto en la conversación. El escaneo de repositorio/build es acotado a patrones y JWT;
no es certificación universal ni inspección de todos los logs privados del equipo.
El escaneo encontró dos access JWT vencidos de otra cuenta ficticia en la base LevelDB del
perfil de navegador `build/pilot-browser/authorized-profile`. Es caché Auth anterior, no un
log de diagnóstico ni parte de Git/APK/web. No se reprodujeron tokens ni se borraron datos.
Su refresh no fue probado: tratar el perfil como material sensible, no compartir la carpeta
`build` completa. Entregar sólo los artefactos de `build/evaluation`; cualquier limpieza o
revocación de esa cuenta anterior requiere autorización separada.

## Recuperación y continuidad

Procedimiento técnico único: [alta y recuperación](alta_institucional_y_recuperacion_v1.md).
Inventario observado: **0 buckets y 0 objetos Storage**; no se descargaron datos remotos.
Los documentos actuales se guardan en PostgreSQL (BYTEA). No hay referencias a objetos
Storage que cotejar hoy; cuando existan, el manifiesto debe relacionar cada registro con
bucket/key/hash/tamaño y detectar faltantes antes de habilitar una restauración.
Consulta agregada remota: 3 registros documentales, 2 con bytes, 0 archivos huérfanos y
0 fingerprints incorrectos; sólo se devolvieron recuentos, no contenido documental.
La restauración local tampoco tiene referencias documentales huérfanas. Sus fixtures de
retención usan deliberadamente el marcador `test` en 7 fingerprints: la restauración
preserva ese dato sintético exactamente, sin presentarlo como validación de hashes de negocio.

Ensayo nuevo aislado: 45 tablas, 13 controles PASS, 4,22 s para dump/cifrado/restore/verificación
en esta computadora. Incluye objeto sintético separado, integridad, funciones, FK, RLS/grants
y denegación de lectura privada anónima. **No es un RTO de Supabase**, ni recupera el servicio
GoTrue, sus identidades completas, configuración de correo, llaves o Storage gestionado.
No se copiaron registros remotos ni se restauró sobre el piloto.

Propuesta pendiente del propietario: RPO 24 h, RTO 1 día hábil para piloto pequeño. Son objetivos
sin garantía hasta probar todo el procedimiento. Designar custodio y suplente, aprobar destino
cifrado y frecuencia; probar restauración completa antes de datos reales. Cifrado AES-GCM,
frase fuera del backup/Git, volumen cifrado/ACL restringida; límite de herramienta actual 256 MiB.
Mantener UUID Auth/FK, rechazar JWT del origen y exigir nuevo ingreso tras recuperación.
Si falta cualquier objeto, política o relación: destino cerrado, original intacto, investigar;
no mezclar parcialmente datos restaurados con producción. Purga y cron permanecen OFF.

[Supabase](https://supabase.com/docs/guides/platform/backups) aclara que un backup PostgreSQL
no contiene bytes de Storage. No se presupone respaldo gestionado del plan gratuito.

## Datos reales: propuesta de privacidad para aprobación

| Categoría implementada | Mínimo propuesto y acceso |
| --- | --- |
| Auth de adultos/operadores | Email, UUID y credencial gestionada por Auth. Password nunca disponible a institución/revisor. No registrar tokens. |
| Incorporación institucional | Nombre/referencia de institución, solicitante, revisión y operador/área/capacidades. Referencia de evidencia, no copias de DNI en texto libre. |
| Adultos y menores | Nombre, nacimiento, vínculo responsable/perfil y decisión revisada. Fecha necesaria para contrato de edad; no crear cuentas de menores sin circuito autorizado. No pedir datos adicionales por conveniencia. |
| Ofertas e inscripciones | Sólo oferta/horario/cupo y estado, institución/área y perfil autorizado. Catálogo público sin identidad de alumnos o responsables. |
| Educación/comunicaciones/calendario | Contenido limitado al propósito educativo, usuarios y ámbitos autorizados. Texto libre puede contener datos sensibles: restringir su uso durante el piloto. |
| Documentos privados | Bytes, metadata, titular/contexto, acceso y vencimiento. Prohibir salud, biometría o documentos sensibles en el piloto hasta aprobación específica. |
| Auditoría | Actor UUID, acción/fecha/referencia. Evitar passwords, contenido documental o nombres en logs de soporte. |

La institución propone ser responsable de finalidad, legitimidad y exactitud del dato educativo;
Atena opera como proveedor bajo instrucciones contractuales. La calidad jurídica definitiva,
responsabilidad de cuentas/soporte y subencargados debe establecerse en contrato, no asumirse.
Confirmar transferencias internacionales: región técnica `sa-east-1` no prueba por sí sola
cumplimiento respecto de Supabase, correo, soporte o subprocesadores.

Propuesta de conservación **sin activarla**: al terminar un piloto, revisar datos en 30 días;
solicitudes rechazadas sin reclamo, 90 días; cuenta inactiva, revisión a 12 meses; auditoría
mínima, 12 meses; backups cifrados rotativos, 30 días. Los registros educativos/documentales
con obligación legal se evalúan por institución y jurisdicción; no asignarles un plazo automático.
No borrar historia ni inscripciones al revocar un responsable. Suspensión de acceso y eliminación
son decisiones distintas. No hay cron/purga aprobados ni promesa de borrado automático.

Procedimiento de derechos: canal de contacto por designar; registrar fecha y número de caso,
verificar identidad/titularidad proporcionalmente, localizar perfil/vínculos/datos/backups,
evaluar restricciones legales/terceros, entregar sólo información autorizada por canal seguro,
corregir con trazabilidad y justificar eliminación o excepción. No borrar la cuenta Auth primero
ni romper FK. Registrar ejecución y asegurar que un restore no reintroduzca datos eliminados.
En Argentina, AAIP informa 10 días corridos para acceso y 5 hábiles para rectificación/supresión;
confirmar aplicabilidad con asesoramiento. No pedir documentos sensibles por chat de soporte.

Antes de datos reales, aprobar: aviso de privacidad adulto/responsable y versión comprensible
para menores; finalidad/base legal por categoría; acreditación de responsabilidad y participación
del menor según corresponda; acuerdos Atena–institución/proveedores; canal/contacto de derechos;
política de conservación/backups; protocolo de incidentes y responsables/suplentes. No inventar
consentimientos ni equiparar verificación técnica de edad con autorización legal completa.

Fuentes: [AAIP derechos](https://www.argentina.gob.ar/aaip/datospersonales/derechos),
[AAIP obligaciones](https://www.argentina.gob.ar/aaip/datospersonales/responsables/obligaciones).

## Guía breve para la primera institución (usar cuando estén habilitados los requisitos)

1. Facundo acuerda responsable, propósito, soporte y alcance ficticio/real aprobado.
2. Representante abre Atena Multiusuario, registra su cuenta individual y confirma el correo.
3. Ingresa y abre Incorporación institucional; envía nombre y referencia de institución.
4. Revisor institucional comprueba representación fuera de Atena y aprueba o rechaza con evidencia mínima.
5. Propietario ingresa de nuevo/actualiza, comprueba institución asignada y configura áreas.
6. Invita a cada operador con su propia cuenta, área y capacidades necesarias, sin compartir acceso.
7. Configura oferta y cupo, guarda borrador, revisa y publica; sólo contenido público aprobado.
8. Adulto/alumno mayor se registra; solicita perfil. Revisor familiar verifica y aprueba.
9. Responsable solicita vínculo con menor; aprobación separada tras acreditar responsabilidad.
10. Alumno/familia busca la oferta y solicita inscripción; no considera confirmado un envío incierto.
11. Institución actualiza solicitudes y confirma; ambas partes actualizan para comprobar estado/cupo.
12. Ante error: anotar versión, hora, operación y código sin datos sensibles; consultar soporte.
    No reinstalar/borrar datos, duplicar solicitudes ni editar cupos manualmente.

No hay sincronización realtime ni cola offline. Durante el piloto, actualizar explícitamente.
Este recorrido es una guía futura; no declara una prueba física/manual realizada.

## Validación de este cierre

- Flutter pertinente: 50 PASS (alta institucional/familiar, contrato remoto y sesiones).
  Línea base completa anterior: 490 PASS; no se repitió por no cambiar código Flutter.
- Retorno: 6 PASS; cifrado: 2 PASS; planes administrativos: 3 PASS; constructor: 8 PASS.
- PostgreSQL: 6 controles nuevos de contención, rollback limpio; recuperación: 13 controles,
  45 tablas. Se conserva la campaña anterior de 375 SQL/96 JWT sin repetir escrituras remotas.
- Nueva verificación remota READ-ONLY: 14 controles PASS, más recuentos de integridad documental.
- Android release y web JavaScript PASS. Avisos Wasm históricos; Wasm no es el build aprobado.
  Manifiesto y APK: `build/evaluation/manifest.json`, `atena-v1-piloto-evaluacion.apk`.
- Análisis: 76 avisos, idénticos al registro anterior, 0 nuevos; salida 1 por esa línea base.
  `git diff --check` sin errores. No se modificaron fuentes Dart, dependencias ni configuración
  Android/web. APK SHA-256: `7c316fa80240d8e53ad2da7df09c7ea83121f000bae3a087271a6813c017f406`.
- Escaneo: 459 archivos tracked, 974 blobs Git alcanzables, 66 archivos web, 453 entradas APK
  y 62 archivos `.log` de build. Sin secretos detectados en distribución/Git; excepción de
  caché de navegador descrita arriba. 312 archivos protegidos sin cambios.
- No se cambió Site URL, SMTP, privilegios, usuarios, datos o migraciones remotas. Sin deployment.
