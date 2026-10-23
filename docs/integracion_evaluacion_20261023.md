# IntegraciÃ³n final del cliente â€” 23/10/2026

Alcance: cliente de evaluaciÃ³n, sin escrituras ni nuevas campaÃ±as Supabase, sin pruebas fÃ­sicas. Se conservan los 312 archivos protegidos. La evidencia remota previa de 31 controles de bajas no se presenta como repetida hoy.

## Reproducciones y correcciÃ³n

Las pruebas nuevas sobre widgets, adaptadores y SDK reales contra HTTP local controlado demostraron:
- Datos de solicitudes anteriores podÃ­an mostrarse si cambiaba/cerraba la sesiÃ³n durante la carga posterior del catÃ¡logo. Se verifica identidad y token antes de renderizar el resultado completo.
- Si una confirmaciÃ³n/baja quedaba aplicada y se perdÃ­a su respuesta, la pantalla conservaba acciones y ocupaciÃ³n antiguas. Ahora consulta el estado del servidor al terminar, tambiÃ©n tras un error. Si esa lectura falla, retira filas/acciones antiguas; no declara Ã©xito ni escribe automÃ¡ticamente.
- PT426 mostraba una sugerencia genÃ©rica de reintento. Ahora exige actualizar la versiÃ³n. Permisos insuficientes tienen mensaje especÃ­fico.

La prueba combinada usa respuestas Auth ficticias: no verifica firmas JWT ni sustituye la autorizaciÃ³n/RLS probada anteriormente. Cubre entrada por el SDK, catÃ¡logo pÃºblico por adaptador, solicitud desde pantalla, navegaciÃ³n institucional, confirmaciÃ³n, consulta familiar, baja e historial desde ambos perfiles. Incluye doble activaciÃ³n de botones. La bÃºsqueda interactiva y la usabilidad del login en un Android real permanecen pendientes.

## Hoja de aceptaciÃ³n para el propietario

Usar exclusivamente las dos cuentas ficticias y el Ã¡rea **TEST telÃ©fonos**; oferta **TEST TELEFONOS - Taller Atena**. No usar las Ã¡reas de campaÃ±as automÃ¡ticas. Instalar como actualizaciÃ³n de Atena Multiusuario, sin borrar datos. No compartir contraseÃ±as ni capturas de accesos.

| Paso | Resultado esperado / PASS |
|---|---|
| InstituciÃ³n ingresa y abre catÃ¡logo reservado | Identidad/Ã¡rea correctas; cinco vacantes iniciales |
| Alumno ingresa, busca oferta y solicita | Solicitud pendiente; enviar no consume cupo |
| InstituciÃ³n actualiza y confirma | Una sola confirmaciÃ³n; cuatro vacantes |
| Alumno actualiza | Confirmada y disponibilidad coincidente |
| InstituciÃ³n da de baja con motivo | ConfirmaciÃ³n explÃ­cita; motivo y actor conservados |
| Ambos actualizan y abren historial | Baja institucional, confirmaciÃ³n anterior y cinco vacantes |
| Actualizar/reintentar sin nueva solicitud | No duplica eventos ni libera otra plaza |
| Cortar conexiÃ³n y recuperarla | Error comprensible; consultar estado antes de repetir; sin Ã©xito local ficticio |
| Cerrar sesiÃ³n/cambiar cuenta | Sin datos o acciones privados de la sesiÃ³n anterior |

FAIL ante identidad ajena, cupos inconsistentes, Ã©xito sin persistencia o pÃ©rdida del historial. Registrar APK/hash, paso, rol, hora y captura sin credenciales; no borrar datos para corregirlo. Refrescar en ambas sesiones: no se afirma realtime.

## Ensayo de recuperaciÃ³n preparado, no ejecutado

Artefactos existentes: `tool/rehearse_local_recovery.py` (dump/restore en otra base localhost), `tool/recovery_bundle.py` y `.mjs` (cifrado autenticado y restauraciÃ³n sin sobrescritura), migraciones/candidatas y procedimiento `docs/alta_institucional_y_recuperacion_v1.md`. Reutilizar la evidencia local registrada allÃ­ y en `docs/operacion_primer_piloto_v1.md`; no se repitiÃ³ la restauraciÃ³n histÃ³rica.

Demostrado previamente: restauraciÃ³n de tablas/FK/polÃ­ticas en PostgreSQL local, bundle cifrado y objeto ficticio separado. No demostrado integralmente: servicio Auth operativo restaurado, Storage como servicio con todos sus objetos y polÃ­ticas, configuraciÃ³n del entorno y funcionamiento conjunto con JWT nuevos. Un dump PostgreSQL no prueba la recuperaciÃ³n de los bytes de Storage.

Procedimiento pendiente:
1. Destino desechable vacÃ­o, aislado del piloto, sin correo saliente, cron ni conexiones al origen. Inventario de versiones, configuraciÃ³n y migraciones; claves nuevas del destino, nunca en Git/logs.
2. Generar exclusivamente fixtures locales ficticios: identidades Auth y dependencias, datos de aplicaciÃ³n, objetos privados y manifiesto de tamaÃ±os/hashes. No copiar datos del piloto en este alcance.
3. Exportar DB y bytes Storage por separado; cifrar el conjunto. Frase fuera del bundle; archivo sensible con acceso restringido. Herramienta existente limitada a 256 MiB.
4. Restaurar en orden de dependencias; comparar filas, FK, secuencias, funciones, RLS/grants, buckets/objetos y referencias. No restaurar sesiones de origen vÃ¡lidas.
5. Probar Auth del destino, acceso autorizado, acceso ajeno/revocado rechazado, objetos privados y enlace vencido. AlteraciÃ³n del bundle/contraseÃ±a incorrecta deben fallar sin salida utilizable. RestauraciÃ³n parcial: destino cerrado, origen intacto.
6. Conservar manifiesto y resultados sanitizados. No borrar ni abrir servicios del destino automÃ¡ticamente.

Recurso pendiente: stack local completo y sano PostgreSQL + Auth + Storage, o proyecto aislado autorizado. El Ãºltimo intento del 22/10 encontrÃ³ archivos faltantes en el PostgreSQL temporal y se detuvo; no es una plataforma confiable para repetir el ensayo. Autorizar por separado reparar/preparar ese runtime aislado o crear un destino remoto, sus costes si existiesen y cualquier copia/importaciÃ³n. No se realizÃ³ ninguna de esas operaciones. Esta preparaciÃ³n no bloquea la evaluaciÃ³n ficticia del APK.

## Resultado automatizado del cliente

- 44 pruebas focalizadas Flutter PASS (ocho nuevas).
- Análisis de los dos archivos Dart afectados: sin incidencias. `git diff --check`: PASS.
- Cero pruebas nuevas contra Supabase real en este bloque; cero escrituras remotas. Se conserva la evidencia remota previa, sin atribuirla a la campaña HTTP simulada.
- APK nuevo previsto: versión 1.0.0+2, bajas ON, recuperación/rectificaciones OFF, mismo proyecto piloto y firma de evaluación. Su resultado de build, commit y SHA-256 se registran junto al artefacto en `build/evaluation/2026-10-23-integracion/manifest.json`. No se considera compilado hasta que ese proceso termine.
- No se declara prueba física ni producción aprobadas.
