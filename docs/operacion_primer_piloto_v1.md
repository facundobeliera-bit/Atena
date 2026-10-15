# Atena V1 — operación del primer piloto

## Estado vigente — 15/10/2026, recta final

Esta sección prevalece sobre los planes y resultados históricos que siguen debajo.
No autoriza cambios remotos. Dominio, Resend, SMTP, recuperación por correo, PKCE,
laboratorio Auth y pruebas físicas/manuales están **pospuestos por el propietario**.
Mantener `password_recovery_requests_enabled=false`; no enviar correos ni activar
recuperación. No ejecutar las instrucciones históricas de Site URL o plantillas.

### Seguridad: incidente contenido en Atena, todavía abierto en Auth

Lectura del piloto `eaegvxxxkvhdukbkydvy` el 15/10/2026 a las 22:28 UTC:

- Proyecto `ACTIVE_HEALTHY`. El bloqueo temporal de la cuenta ficticia afectada
  venció a las 18:03:56 UTC (15:03:56 Argentina).
- Atena conserva `disabled=true` y su corte de sesiones. No tiene vencimiento.
- Cero vínculos familiares activos, operadores, vínculos institucionales o roles
  de revisión activos para esa cuenta.
- Auth conserva una fila de sesión y una fila de refresh token sin revocar.
  **No se reprodujo el token ni se probó un login.** La fila no demuestra que el
  token expuesto siga utilizable, pero tampoco permite afirmar su invalidación.
- El guard remoto coincide exactamente con el probado localmente. Ocho controles
  locales PASS: cambio de credencial, sesión posterior legítima, ban vencido,
  bloqueo de sesiones viejas/nuevas, rechazo privado y rollback sin fixtures.

No confundir contención de datos privados de Atena con revocación de Supabase Auth.
Antes de datos reales, cerrar administrativamente el incidente. Se necesita autorización
específica para invalidar las sesiones/credenciales de **esa única cuenta ficticia**
y bloquear su ingreso Auth mediante mecanismos soportados, manteniendo la deshabilitación
de Atena y sin borrar la identidad ni sus dependencias. La revocación puntual de sesiones
no impide nuevos ingresos si una credencial permanece válida. Un ban temporal tampoco
debe describirse como cierre permanente. No reutilizar el secreto expuesto para investigar.

### Operación cotidiana y primera institución

La lectura actual encuentra **0 revisores institucionales y 0 familiares activos**.
Las pantallas para revisar, aprobar/rechazar y revocar ya existen. No hace falta un
panel nuevo, pero no puede completarse una nueva adhesión mientras no haya un revisor.
La designación inicial requiere custodio técnico, cuenta verificada y autorización
remota por alcance, usando la herramienta administrativa existente. Después, las
decisiones ordinarias se toman desde Atena, sin editar tablas ni compartir claves.
El propietario institucional administra áreas e invitaciones limitadas desde la app.

Guía breve para una institución interesada:

1. **Presentación:** usar sólo las identidades ficticias habilitadas. Mostrar perfil,
   oferta/turno/cupo, búsqueda y seguimiento. No prometer alta real ni recuperación.
2. **Demostración:** el escenario reservado «TEST TELEFONOS - Taller Atena» continúa
   publicado, activo, con capacidad 5, ocupación 0 y solicitudes activas 0. No se consumió
   en esta revisión. Su ejecución manual sigue pospuesta; no está marcada PASS.
3. **Solicitud de adhesión futura:** acordar alcance y responsables antes de introducir
   datos reales. No recibir documentación personal por este canal de diagnóstico.
4. **Habilitación futura:** resolver correo, designar revisores y verificar representación
   mediante aprobación explícita. Registrarse no concede una institución ni permisos.
5. **Operación:** propietario crea áreas, invita con permisos mínimos, configura y publica
   ofertas. Alumno/responsable autorizado solicita; institución decide; ambos actualizan
   para comprobar estado y cupo. No hay cola offline ni sincronización realtime.
6. **Incidencia:** conservar datos; registrar versión, hora, operación y código de error
   sin tokens ni contenido educativo. Actualizar antes de reintentar. No recrear cuentas,
   editar cupos por SQL ni borrar datos para resolver un error.

### Recuperación y límites

Se conserva la evidencia del ensayo local cifrado: 45 tablas y 13 controles, incluyendo
integridad, RLS/permisos y un objeto ficticio separado. Las pruebas del contenedor cifrado
comprueban contraseña incorrecta, alteración y no sobrescritura. No se repitió el restore
sin cambios de implementación. Esto **no restaura Supabase completo**: siguen pendientes
destino aislado autorizado, inventario/copia de objetos privados, dependencias y configuración
Auth, configuración del servicio y prueba conjunta de recuperación. No copiar el piloto ni
restaurar sobre él sin permiso. No activar purga ni fijar retención automáticamente.

La lectura conservó las filas históricas de 38 tablas y los usuarios Auth anteriores a
la campaña familiar. El escenario de teléfonos no cambió. Comercial y purga permanecen OFF.
La matriz única sigue siendo [matriz_validacion_integral_v1.md](matriz_validacion_integral_v1.md),
íntegramente pendiente de ejecución manual. La presentación ficticia es distinta de operar
con datos reales: faltan cierre del incidente, responsables/revisores, entrega de correo,
recuperación integral, privacidad/conservación aprobadas y evaluación de uso.

### Evidencia de este cierre

- 169 tests Flutter focalizados PASS, sin omitidos: alta y revisión institucional/familiar,
  contratos remotos, catálogo público, publicación, solicitudes, capacidad, identidad,
  navegación y logout. Son regresiones locales/HTTP controlado; no una campaña JWT nueva.
- 8 controles SQL locales de contención PASS, con rollback; 13 tests de constructor y
  administración PASS; 2 tests de respaldo cifrado PASS. No se repitió la suite general.
- 66 funciones remotas coinciden con el esquema local previamente probado. Se conserva
  la evidencia anterior de alta/JWT y concurrencia, sin nuevas escrituras remotas.
- Análisis: 76 avisos, exactamente iguales a la línea base, 0 nuevos; salida 1 por esos
  avisos históricos. No se modificaron los archivos históricos para silenciarlos.
- Builds Android release y web JavaScript PASS. Los avisos del sondeo Wasm son históricos;
  no se certifica Wasm. Artefacto privado: `build/evaluation/atena-v1-piloto-evaluacion.apk`;
  proyecto piloto y recuperación deshabilitada. Identidad, firma y hashes en el manifiesto
  contiguo. La fuente funcional corresponde a `575e5b0`; este cierre sólo modifica esta guía.
- No aparecieron defectos funcionales nuevos en los circuitos ejecutados. Se corrigió
  documentación operativa obsoleta, sin atribuir a este bloque mejoras funcionales anteriores.
- Escaneo por patrones: 467 archivos tracked, 67 archivos web y 453 entradas APK sin
  hallazgos de claves privilegiadas, claves privadas o JWT de sesión piloto. No es prueba
  universal de ausencia de secretos. Los 312 protegidos mantienen sus hashes;
  `git diff --check` PASS. No compartir perfiles de navegador ni la carpeta `build` completa.

Fecha: 14/10/2026. Proyecto exclusivo: `eaegvxxxkvhdukbkydvy`, región `sa-east-1`.
Este documento es una propuesta operativa; no autoriza publicación, cambios remotos,
uso de datos reales ni eliminación. No sustituye asesoramiento jurídico.
No cambia el funcionamiento de Flutter ni crea nuevos módulos.

Decisión posterior del propietario: dominio y SMTP externo **pospuestos**. Las opciones
de proveedor de esta guía quedan como referencia, no como trabajo a activar. Tampoco están
autorizados la publicación del Worker, Site URL ni nuevos permisos remotos.

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

Verificación API del 14/10: Worker `atena-staging`, versión activa
`3030452d-1e1e-4187-9346-3f3d709679dd` con 100% del tráfico; compatibility date
`2026-09-15`, workers.dev y previews habilitados, bindings/rutas vacíos, Logpush OFF y
observability sin configurar. La versión informa assets `serve_directly=true`,
`raw_run_worker_first=false`, sin handlers dinámicos. No se modificó nada.
La [tarifa oficial de Static Assets](https://developers.cloudflare.com/workers/static-assets/billing-and-limitations/)
no cobra almacenamiento ni solicitudes estáticas. Publicar el retorno en este Worker no
requiere dominio, Worker nuevo, SMTP ni plan adicional; no se afirma que la cuenta completa
carezca de otros cargos. El pago/dominio no bloquea técnicamente este retorno: falta autorización.

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

### Recuperación de contraseña preparada localmente — 2026-10-15

**Implementada y probada por contratos locales; NO habilitada ni validada de extremo a extremo remoto.**
No se cambiaron Site URL, SMTP, plantillas remotas, RLS, usuarios ni contraseñas.

- Ambos accesos Flutter abren la solicitud remota. El modo local mantiene el reset legacy
  deshabilitado. El SDK solicita `resetPasswordForEmail` sin consultar cuentas ni reutilizar
  la sesión habitual. Una respuesta neutral idéntica cubre cuentas inexistentes, límites y
  errores: no certifica entrega. Los límites y posibles diferencias de tiempo del proveedor
  requieren comprobación remota; no se promete resistencia absoluta a análisis temporal.
- El retorno usa exclusivamente los endpoints oficiales de Supabase Auth. No implementa
  un sistema de autenticación propio. La plantilla propuesta está en
  `supabase/templates/recovery.html`: `.TokenHash` en el fragmento, nunca contraseña.
- Se limpia la URL antes de operar. Sólo un código de ese formato y una pulsación explícita
  permiten `POST /auth/v1/verify` con `type: recovery` fijo. Un `type` inventado no concede
  autoridad: Auth debe verificar el código. Tokens de signup, JWT recibidos por URL,
  códigos PKCE y parámetros en query no habilitan el formulario.
- El bearer se conserva sólo en memoria de esta página, durante un máximo utilizable de
  diez minutos y nunca se entrega a Flutter, almacenamiento, logs o canales entre pestañas.
  El refresh token se descarta. Se exige contexto del mismo usuario y guard versión 1 antes
  de mostrar el formulario y nuevamente antes de actualizar. No se crean roles ni vínculos.
- Auth confirma `PUT /auth/v1/user` con la nueva contraseña. Se comprueba luego que el guard
  rechace esa sesión anterior y se solicita `POST /auth/v1/logout?scope=global`.
  Si alguna comprobación falla, se informa que el cierre está pendiente, sin declarar éxito
  de revocación. Ante error de red durante el cambio se informa resultado incierto y no se
  repite automáticamente. La persona debe volver al ingreso o pedir otro enlace.
- El disparador existente por cambio de credencial establece el corte de sesiones de Atena.
  Un JWT todavía criptográficamente válido no equivale a acceso privado permitido. No se
  cambió ese disparador ni se promete revocación criptográfica instantánea de access tokens.
- La página no lee ni modifica datos educativos ni cambia la sesión habitual de otro usuario.
  Al volver, Atena valida su propia sesión contra el servidor. No se navega automáticamente
  a un área privada desde el correo. Android vuelve a la aplicación; web al inicio.
- CSP limita la red al piloto y fija el hash del script; cabeceras locales propuestas impiden
  cacheo/iframe. El constructor excluye el retorno del caché offline generado por Flutter.
  Una instalación web con un service worker antiguo debe actualizarse antes del ensayo.
  Un build web directo sin el constructor no inyecta la clave pública y falla cerrado.

**Activación pendiente: autorización separada, en este orden.**

1. Publicar el build web completo preparado en el Worker existente, sin cambios de rutas ni
   fallback. Verificar HTTPS 200 en `/auth/return.html`, cabeceras, contenido/configuración
   públicos y actualización del service worker. No publicar sólo la carpeta `auth`.
2. En el piloto `eaegvxxxkvhdukbkydvy`, autorizar únicamente la plantilla **Recovery** con el
   contenido exacto de `supabase/templates/recovery.html` y añadir a la lista de redirect URLs
   `https://atena-staging.facundobeliera.workers.dev/auth/return.html`, preservando otras entradas.
   No cambiar Site URL, SMTP ni plantilla de confirmación. No usar el ConfirmationURL estándar
   para recovery: consume el código antes de este retorno y éste rechaza esos tokens.
3. Autorizar una prueba automatizada aislada con una cuenta ficticia dedicada y un buzón de
   pruebas consentido. Sin ello no enviar correos ni modificar contraseñas existentes.
   Verificar con **enlace real**: código de recovery válido, signup rechazado aunque se cambie
   su tipo, vencido/reutilizado rechazados, contraseña nueva válida/anterior inválida, permisos
   intactos, refresh anteriores rechazados, JWT anteriores sin acceso privado, otro usuario
   intacto. Documentar resultados reales. No sustituirlo por generación administrativa de sesión.
4. Sólo después habilitar las solicitudes con `--password-recovery-ready` en
   `tool/build_pilot_evaluation.py`. El manifiesto registra el flag. Sin él, el APK y la web
   informan que la recuperación está pendiente de habilitación y no envían correos.

La entrega genérica del correo continúa limitada por el servicio predeterminado y su cuota;
Resend, dominio y SMTP siguen pospuestos. Este circuito no necesita una migración ni permisos
nuevos. Sin JavaScript, con history fallando, host inaccesible o navegador/extensión capturando
la URL, no puede garantizarse eliminación absoluta del enlace en todos los sistemas: se falla
cerrado y no se debe compartir la dirección. El fragmento evita enviarlo en la petición HTTP;
los logs internos de Auth/correo no son controlados por esta página.

Referencias oficiales: [plantillas Auth](https://supabase.com/docs/guides/auth/auth-email-templates),
[recuperación](https://supabase.com/docs/guides/auth/passwords),
[verifyOtp](https://supabase.com/docs/reference/javascript/auth-verifyotp).

Validación de esta unidad: 47 casos Flutter relacionados PASS (10 nuevos), 15 casos del
retorno con HTTP controlado PASS, 10 del constructor PASS y 8 SQL locales de sesiones PASS.
No se repitió la suite completa ni se enviaron correos reales. Análisis global: 76 avisos
históricos; análisis de los Dart modificados: 0 avisos. Builds Android y web JavaScript PASS.
El `_headers` cubre tanto `/auth/return.html` como su ruta canónica, conforme a las
[reglas de Static Assets](https://developers.cloudflare.com/workers/static-assets/headers/).
El APK de evaluación mantiene `password_recovery_requests_enabled=false`; no es prueba
de recuperación operativa. Controles por patrones sin secretos en fuente/builds y los
312 archivos protegidos sin cambios. `git diff --check` PASS.

## SMTP recomendado para evaluación del propietario

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
Consulta reproducible preparada: `supabase/diagnostics/pilot_incident_containment_readonly.sql`.
Sólo devuelve estado, recuentos y fingerprint de la función; nunca cierra el incidente por
observar `disabled=true`. Fue ejecutada por lectura y conserva `incident_closed=false` y
`credential_invalidation_verified=false`. Después del vencimiento deberá comprobarse también
Auth/refresh y operaciones privadas mediante prueba aislada autorizada, sin publicar credenciales.
La invalidez criptográfica de un access JWT vencido no demuestra invalidez del refresh.

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

Escenario reservado comprobado sólo por lectura: «TEST TELEFONOS - Taller Atena», recurso
activo y publicado, cupo 5, ocupación 0, solicitudes activas 0, vínculo solicitante habilitado.
No se consumió ni reinició. Las identidades ficticias existentes se conservan sin alterarlas;
no se crearon cuentas ni se probaron passwords. La entrega segura de acceso se resolverá al
autorizar la demostración, sin incorporar credenciales a esta guía ni al APK.

## Evidencia del cierre operativo anterior

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

## Cierre técnico posterior — alcance disponible completado

- Se corrigió el mensaje del retorno de recuperación y su CSP; no se implementó un reset
  parcial ni se reabrió el reset legacy. **Recuperación remota de contraseña: funcionalidad
  pendiente**, independiente de contratar SMTP. Requiere desarrollo/validación del contrato
  indicado en la matriz, no sólo habilitar un proveedor.
- Regresiones afectadas: 28 Flutter PASS, 7 retorno PASS y 8 SQL locales PASS. Los dos nuevos
  controles SQL comprueban corte tras cambio de credencial y nueva sesión legítima antes de
  deshabilitar. Son fixtures locales; no equivalen a otra campaña Auth/JWT remota.
- Consulta del incidente ejecutada exclusivamente READ-ONLY: cuenta encontrada, ban aún activo,
  Atena deshabilitada, una sesión Auth, cero vínculos solicitantes. Incidente **ABIERTO/CONTENIDO**,
  no cerrado hasta la prueba posterior al vencimiento y rechazo de credenciales expuestas.
- No se repiten las 375 pruebas SQL, 96 JWT, recuperación de 45 tablas ni la suite Flutter
  completa: no hubo cambios en su implementación. Las fuentes Dart/Android/dependencias están
  intactas; se verifica el build de evaluación con el único cambio estático de retorno.
- SMTP/dominio pospuestos: bloquean la entrega general fiable, no el hosting del retorno ni
  las funciones de cuentas previamente habilitadas. No presentar correo a usuarios reales como
  operativo con el proveedor actual de 2/hora y destinatarios restringidos.
- Autorización remota futura: publicación del build completo/retorno y Site URL, designación
  inicial de revisores por alcance y ensayo de recuperación integral en destino aislado.
  No hubo nuevos usuarios, permisos, fixtures, consumo del escenario ni cambios de configuración.
- Para datos reales siguen siendo obligatorios privacidad/menores, soporte y custodios,
  conservación aprobada y recuperación completa. Nada de esto se sustituye por un PASS técnico.
- Compilación de este bloque: Android release y web JavaScript PASS. Retorno del build igual
  a la fuente corregida; firma/paquete/proyecto del APK verificados por el constructor existente.
  Escaneo de 66 archivos web y 453 entradas APK sin hallazgos de secretos; 312 protegidos
  idénticos. `git diff --check` PASS. No hubo actualización de dependencias ni nuevo análisis
  Dart: no cambió código Dart, y la última comparación mantiene los 76 avisos históricos.
