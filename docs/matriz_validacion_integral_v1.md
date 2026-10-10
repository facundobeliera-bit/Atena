# Matriz única de validación integral V1

Estado de TODAS las filas: **PENDIENTE — no ejecutada manualmente**.
Fecha de preparación: 10/10/2026. No iniciar hasta indicación del propietario.
Sólo piloto ficticio, APK/web cuyo hash figure en `build/evaluation/manifest.json`.
A = operador previamente habilitado; B = solicitante con perfil vinculado;
C = identidad ajena sin permiso. No incluir contraseñas, tokens ni datos personales en evidencias.
Antes de ejecutar, confirmar oferta/cupo inicial con el responsable del escenario;
no reiniciar ni consumir el escenario reservado en la preparación.

Registrar por fila: fecha, plataforma/versión, identidad ficticia por alias, resultado,
evidencia redactada y defecto. PASS sólo si se cumple **todo** el resultado esperado;
FAIL ante discrepancia. BLOQUEADA si falta una autorización/capacidad, no convertirla en PASS.
N/A sólo con función inexistente documentada y decisión del responsable, nunca para ocultar un fallo.

| ID | Rol / módulo | Acción futura | Criterio objetivo PASS / condición de FAIL |
| --- | --- | --- | --- |
| D01 | Distribución | Instalar actualización de evaluación conservando datos | Mismo paquete/certificado; datos locales anteriores intactos. Firma incompatible o pérdida = FAIL. |
| D02 | Entorno | Abrir APK/web piloto | Acceso identifica cuentas piloto; endpoint esperado. Datos de otro entorno o fallback silencioso = FAIL. |
| I01 | Institución nueva | Intentar alta multiusuario | BLOQUEADA actualmente: requiere onboarding verificado. Registro local NO prueba alta remota. |
| I02 | Institución habilitada | Login y abrir área autorizada | Identidad/operador/área correctos; ningún contexto arbitrario. |
| I03 | Operador ajeno | Intentar abrir otra institución/área | Denegado sin datos privados ni escritura. |
| I04 | Administración | Invitar/asignar/bajar operador autónomamente | BLOQUEADA: no existe flujo remoto autónomo validado. No sustituir por asignación manual y marcar PASS. |
| O01 | Ofertas | Crear borrador, salir y volver | Datos reaparecen para operador autorizado; no visibles públicamente. |
| O02 | Ofertas | Editar y publicar | Servidor confirma versión; B y anónimo ven oferta/cupo correcto tras actualizar. |
| O03 | Concurrencia de edición | Dos sesiones editan misma revisión | Edición obsoleta rechazada; primera guardada no se pierde. |
| O04 | Ofertas | Retirar publicación | Desaparece del catálogo público; solicitudes previas conservadas. |
| O05 | Cupos | Intentar reducir capacidad por debajo de confirmados | Rechazo; ocupación y solicitudes intactas. |
| A01 | Alumno | Login, seleccionar perfil autorizado | Sólo sus perfiles; datos de otro perfil no aparecen. |
| A02 | Catálogo público | Buscar sin sesión y abrir oferta | Información publicada accesible, borradores/datos privados ausentes. |
| A03 | Inscripción | Solicitar desde B | Confirmación del servidor y solicitud pendiente visible para B y A. |
| A04 | Duplicados | Repetir solicitud o doble toque | No duplica solicitud activa ni cupo; respuesta explícita/idempotente. |
| A05 | Gestión | A confirma y B actualiza | Estado confirmado en ambos; ocupación aumenta exactamente una vez. |
| A06 | Gestión | Repetir confirmación | Estado/cupo sin incremento adicional. |
| A07 | Último cupo | Dos solicitudes compiten por capacidad 1, escenario autorizado aparte | Exactamente una confirmada; sin ocupación > capacidad. No consumir escenario reservado sin permiso. |
| A08 | Gestión | Rechazar/cancelar según rol y estado permitidos | Estado consistente y liberación de cupo sólo cuando el contrato lo exige. No reactivar terminal por reintento. |
| F01 | Familia | Consultar perfil vinculado autorizado | Sólo información de ese perfil. Un vínculo local o correo coincidente no autoriza remoto. |
| F02 | Tutor nuevo | Acreditar representación y vincular menor | BLOQUEADA: no hay alta autónoma/consentimiento de tutor validado. No usar menores reales. |
| C01 | Calendario | A publica actividad dirigida; B actualiza | Actividad persistida sólo para destinatarios autorizados. |
| C02 | Calendario | B responde y A consulta | Respuesta persistida con autor/contexto correcto, sin duplicados al reintentar. |
| C03 | Comunicaciones | Publicar, consultar y responder donde esté permitido | Sólo destinatarios; respuesta visible tras refrescar; sin atribuir otra identidad. |
| E01 | Progreso | Guardar y consultar registro ficticio | Persistencia remota y acceso exclusivo del perfil/área autorizados. |
| E02 | Boletines | Guardar y consultar registro ficticio | Misma verificación de persistencia, autoría y privacidad. |
| E03 | Títulos | Guardar y consultar registro ficticio | Misma verificación; no afirmar validez oficial de datos de prueba. |
| E04 | Becas | Guardar y consultar registro ficticio | Persistencia, autoría y privacidad. |
| E05 | Sanciones | Guardar y consultar registro ficticio | Persistencia, autoría y privacidad; sin acceso de otro perfil. |
| E06 | Equivalencias | Guardar y consultar registro ficticio | Persistencia, autoría y privacidad. |
| DOC01 | Documentos | Solicitar, cargar archivo ficticio y abrir autorizado | Bytes correctos, acceso privado; ninguna URL pública utilizable por tercero. |
| DOC02 | Documentos | Intentar abrir como C/anónimo | Denegado; sin contenido ni metadata sensible. |
| DOC03 | Documentos | Abrir fixture de acceso vencido | Rechazo; no implica borrado del archivo ni activación de purga. |
| S01 | Sesión | Logout, Back, root y reabrir/F5 | Área privada no reaparece; menú principal disponible. |
| S02 | Sesión | Cambio de contraseña en cuenta aislada autorizada | Antigua rechazada; JWT previos/renovados de sesiones antiguas no acceden a Atena privada. |
| S03 | Sesión | Cerrar todas las sesiones en cuenta aislada | Ambas pierden acceso privado; refresh antiguos rechazados; catálogo público puede seguir accesible. |
| S04 | Sesión | Cambiar identidad con petición pendiente | Respuesta anterior no se muestra ni modifica contexto de nueva identidad. |
| S05 | Permisos | Revocar sólo asignación de prueba autorizada | Siguiente operación denegada; otras áreas intactas; historial conservado. |
| N01 | Red | Cortar conexión antes de guardar | Error recuperable, ningún mensaje de éxito ni copia local presentada como remota. |
| N02 | Red | Interrumpir respuesta después de envío | Reconsultar/reintentar misma operación; resultado único y cupo correcto. |
| N03 | Red | Reconectar y actualizar | Reaparece estado confirmado por servidor, no una mezcla local/remota. |
| R01 | Recuperación | Ensayo autorizado en destino aislado | Recuentos/hashes/constraints/RLS/funciones/documentos iguales; login y sesiones reconciliados; nunca restaurar sobre piloto activo. |
| L01 | Modo local separado | Abrir build local con datos ficticios propios | Registro/sesión/solicitudes locales independientes; no se anuncian como compartidos. |

Cierre: no habilitar datos reales si hay FAIL de identidad, privacidad, integridad,
cupos o recuperación. Las filas bloqueadas requieren decidir alcance/implementación;
no declarar que una institución nueva puede incorporarse autónomamente mientras I01/I04 sigan bloqueadas.
No declarar producción lista a partir de esta matriz pendiente.
