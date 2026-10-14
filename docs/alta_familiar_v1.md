# Alta de alumnos y familias — candidato local V1

Estado: implementación local validada; **NO aplicada ni probada remotamente en este bloque**.
No se crearon cuentas remotas, no se cambiaron contraseñas, RLS ni escenarios de teléfonos.

## Recorrido y autoridad

En modo multiusuario, Registrarme en Acceso de alumnos abre el alta Supabase, no el registro local.
Se reutilizan signup/PKCE y el control de identidad/token del alta institucional. La confirmación
del correo sigue siendo obligatoria en el servidor. Después del login, Cuenta → Mis perfiles y
vínculos familiares permite solicitar y consultar la revisión. El modo local conserva su registro.

Un adulto solicita su propio perfil indicando nombre y nacimiento. Declarar una edad **no**
concede permisos: un revisor debe comprobar identidad y edad, registrar una referencia de
evidencia sin datos sensibles y confirmar explícitamente la revisión. No se afirma comprobación
oficial automática. Los permisos de revisor familiar son independientes de los institucionales;
nadie puede autoaprobarse ni designarse revisor desde Flutter.

Una vez aprobado, el adulto puede pedir un perfil de menor o la vinculación a uno existente.
Conocer un código, correo, DNI o nombre no autoriza ninguna lectura privada. Los códigos se
comprueban al aprobar, sin revelar a un solicitante pendiente si el perfil existe. La aprobación
de un vínculo exige además comprobar responsabilidad autorizada. El mismo menor puede tener
varios adultos revisados de manera independiente; no se duplica el perfil ni se reemplaza a su
responsable original. Un reintento conserva su operación y no duplica la solicitud; se bloquea
también recrear el mismo menor por el mismo solicitante después de su aprobación.

Tras aprobar, volver a Cuenta actualiza los perfiles. El recorrido existente permite buscar,
solicitar y ver estados/inscripciones confirmadas. El autor de la solicitud queda registrado,
pero otro responsable autorizado del mismo perfil puede consultar esa inscripción. La RLS
decide el acceso; el filtro Flutter no concede autoridad.

Revocar un vínculo impide nuevas operaciones y lecturas privadas, incluso con una sesión
anterior. No borra inscripciones ni libera cupo. Otro responsable autorizado conserva acceso.
Revocar el perfil adulto desactiva también sus autorizaciones familiares. Al cumplir 18 años,
cesa el acceso de responsables: la persona puede solicitar «Mi perfil existente · ya cumplí
18 años». Una revisión independiente verifica su identidad y conserva el identificador y el
historial; no se vincula automáticamente por coincidencias de datos.

Los perfiles legacy se conservan, sin reasignaciones automáticas. Su eventual vinculación a
identidades nuevas requiere un procedimiento de migración específico; el alta nueva no permite
apropiarse de ellos. Restaurar una autorización revocada de un adulto existente no está ofrecido
como autoservicio; requiere evaluar y autorizar un procedimiento administrativo separado.

## Contrato SQL

Archivo: `supabase/candidates/20261013000000_family_onboarding.sql`, después de `20261010000000`.
Una transacción; no elimina filas ni modifica usuarios, contraseñas, precios o política de purga.

- `family_profiles`: identidad/nacimiento revisados, identificador generado por servidor.
- `family_applications`: solicitudes, reintentos, decisiones y referencias de revisión.
- `family_reviewers`: designaciones explícitas; no copia revisores institucionales.
- `family_audit`: autor de decisiones y revocaciones. Designación por servicio privilegiado
  identificada expresamente como tal, sin atribuirla falsamente al usuario designado.
- `applicant_access`: autorizaciones por perfil/usuario; inicialmente refleja enlaces legacy.
- `authorized_applicants`: vista bloqueable que filtra revocaciones y edad. Las consultas y
  bloqueos existentes se conservan, cambiando sólo su fuente de autorización.

Los anclajes `applicant_links` no se sustituyen: sus FK de documentos/calendario siguen válidas.
Un trigger refleja cambios legacy. El FK compuesto de solicitudes pasa a las autorizaciones,
manteniendo actor, perfil y unicidad por grupo. Las lecturas institucionales de historial usan
la existencia de algún responsable válido; confirmar una solicitud pendiente sigue exigiendo
la autorización de quien la creó. No cambian los bloqueos transaccionales de capacidad.
La política RLS restrictiva de sesión sigue instalada. Tablas/vista privadas sin acceso directo.

RPC autenticadas: `atena_family_state`, `atena_family_command`. Ambas comprueban sesión vigente
y correo verificado. Acciones: apply, approve, reject, revoke. No se acepta autoridad del cliente.
RPC administrativa: `atena_family_reviewer`, sólo service_role; nunca llamada desde Flutter.
La migración conserva las definiciones instaladas de RPC y cambia su referencia de lectura;
si detecta un escritor inesperado de enlaces antiguos aborta. Antes de aplicar remotamente
hay que contrastar definiciones/dependencias y revisar el diff efectivo del candidato.

## Evidencia automática y límites

- Suite Flutter completa: **490 PASS, 0 skipped**. Incluye 14 pruebas familiares nuevas y
  el contrato actualizado de navegación de registro. SDK HTTP local: registro sin sesión
  inventada, identidad contradictoria, cambio de cuenta, fallo de conexión, revisión explícita,
  autoaprobación oculta e historial compartido entre responsables.
- PostgreSQL local: **69 nuevas + 306 de regresión = 375 PASS**. Institución y familia se
  incorporan mediante RPC; sólo usuarios/sesiones ficticios y designación explícita de revisores
  se preparan como fixtures. No hay inserciones manuales de perfiles/vínculos/asignaciones.
- Se prueba correo sin verificar, duplicados, aislamiento, revisión, revocación, cambio a adulto,
  inscripción propia y familiar, confirmación idempotente y agotamiento. Dos conexiones reales
  compiten por cupo 1: una confirma, otra recibe conflicto. Filas de todas las tablas anteriores
  idénticas antes/después de aplicar el candidato local.
- SQL usa claims y filas Auth ficticios. **No constituye una nueva validación JWT/GoTrue remoto
  ni entrega real de correo**. Esas comprobaciones se ejecutarán tras autorización remota.
- Análisis: 76 avisos históricos, 0 nuevos. Android release/web JavaScript: PASS.
- Matriz manual única actualizada, íntegramente pendiente. No hubo pruebas físicas/manuales.

Reproducción local: `python tool/test_family_onboarding.py --psql RUTA_PSQL --port PUERTO_LOCAL`.
Requiere un servidor aislado con roles anon/authenticated/service_role. Crea base desechable;
no acepta host remoto. Pruebas Flutter: `flutter test`; no requieren configuración Supabase real.

## Operaciones pendientes de autorización, en orden

1. **Piloto eaegvxxxkvhdukbkydvy — esquema.** Revisar historial/definiciones remotas, snapshot de
   integridad y aplicar exclusivamente `20261013000000_family_onboarding.sql` una vez. Riesgo:
   cambia la fuente de autorización de solicitantes; requiere pruebas negativas y JWT reales
   antes de habilitar a nuevos participantes. No aplicar si existen modificaciones incompatibles.
2. **Piloto — revisor familiar ficticio.** Elegir UUID de una cuenta confirmada y autorizar la
   designación limitada. Preparar sin ejecutar: `python tool/onboarding_admin.py --scope family
   --reviewer-user UUID`. Ejecutar sólo con autorización y credencial administrativa fuera del
   cliente; el flag explícito de ejecución mantiene el proyecto piloto fijado. Aprobaciones y
   revocaciones posteriores se realizan desde la pantalla; no editar tablas manualmente.
3. **Piloto — campaña ficticia Auth/JWT.** Autorizar cuentas/datos aislados, correo real y
   recorrido adulto/menor/segundo responsable/revocación/inscripción. No consumir el escenario
   reservado para teléfonos. Ningún PASS remoto de esta ampliación está declarado todavía.
4. **Hosting y Auth.** Autorizar publicación de `web/auth/return.html` y comprobar acceso a
   `https://atena-staging.facundobeliera.workers.dev/auth/return.html`; después cambiar exactamente
   Site URL. Última configuración observada: localhost:3000. No ampliar redirects con comodines.
   Entrega de correo/SMTP operativo y límites deben comprobarse antes de incorporar usuarios.
5. **Recuperación.** Autorizar destino Supabase aislado e inventario/copia exclusivamente
   ficticios (PostgreSQL, objetos Storage, configuración y dependencias Auth). No restaurar en
   el piloto. El ensayo local cifrado no equivale a restaurar servicios gestionados completos.

Ante fallo remoto: no borrar datos ni recrear perfiles. Si falla la transacción, rollback
automático; si ya se confirmó, conservar evidencia y detener altas. Una suspensión temporal
de las dos nuevas RPC o reversión adicional requiere autorización, preservando datos y
verificando que el resto de autorizaciones no se amplía. No activar purga ni revocación masiva.

Antes de datos reales siguen pendientes decisiones de privacidad, representación, custodia,
conservación y operación. Este candidato no certifica producción ni verificación legal.
