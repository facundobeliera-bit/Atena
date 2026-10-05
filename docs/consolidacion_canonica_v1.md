# Atena — consolidación canónica V1 y evolución pública

Fecha: 05/10/2026. Integración local, sin commit, push ni deployment.

## Decisión de base y matriz de integración

Base: raíz del repositorio, branch `fix/buscar-instituciones-alumno`, HEAD `fb1388ccc14741e6e10cd12d36eca5712db59faf`, incluyendo TODO el trabajo previo sin commit. Origen: `https://github.com/facundobeliera-bit/Atena.git`.
Referencia visual: copia separada `atena-preview-amigo`, commit `8203832f5ccc8f64e6a8ca99eb51c8a30640d54d`. Autor registrado: Franco Agostinelli. No sustituye a la raíz. No se borró ninguna versión.

| Componente | Decisión | Implementación consolidada |
|---|---|---|
| Plus Jakarta Sans / Cinzel | KEEP | Archivos de fuente y licencias OFL, sin descarga en ejecución ni dependencia nueva. |
| Temas, jerarquía y tarjetas | ADAPT | `AtenaTheme`, `AtenaActionCard` y componentes del workspace canónico. |
| Portada | REIMPLEMENT | Presentación de categorías, accesos existentes a ambos roles y aviso local. Mantiene bootstrap y callbacks canónicos. |
| Panel alumno / institución | REIMPLEMENT | Tarjetas adaptativas, alturas naturales y acciones existentes. No adopta rutas/servicios del tercero. |
| Buscador | ADAPT | Categorías públicas, tarjetas con nombres/costos de actividades, filtros reales, estado vacío, normalización de tildes. |
| Perfil público | ADAPT | Terminología y jerarquía compartidas; no presenta verificación externa inexistente. |
| Seis módulos educativos | CONSERVAR + ADAPT | Accesos adaptativos sobre los mismos servicios, permisos, registros y PDFs. |
| Autenticación del tercero | REJECT | Incompatible con PBKDF2 600.000, migración e invalidación canónicas; recuperación DNI/CUIT rechazada. |
| Persistencia / vacantes / solicitudes del tercero | REJECT | No conserva historial, áreas, operadores ni todos los controles de capacidad. |
| Prueba del tercero con D:/flutter | REJECT | No se importa. Ninguna prueba consolidada depende de esa ruta. |
| Backend | CONSERVAR | Piloto, SQL diagnóstico, candidatos y pruebas permanecen intactos. No se aplica SQL remoto. |

La comparación inicial completa está conservada fuera del repositorio en `auditoria-amigo/informe.md` e `inventario.md`. La integración no importa `lib/` del tercero: reutiliza fuentes y adapta experiencias sobre la raíz.

## Contratos que no cambian

- Identidad institucional: institución + área + operador; propietario no se convierte en director.
- PBKDF2-HMAC-SHA256 600.000, sal aleatoria, migración individual de identidades divergentes; recuperación insegura deshabilitada; invalidación tras cambio de contraseña.
- Registro institucional, recuperación de registro parcial, selección de plan, horarios y navegación: conservados.
- Grupos: fuente vigente prevalece; `[]` explícito no reactiva histórico. Ocupación efectiva sigue siendo máximo de persistida y confirmada.
- Solicitudes: validación de cupos, grupos activos/existentes, idempotencia, permisos y autoría canónicos.
- Progreso, boletines, títulos, becas, sanciones y equivalencias conservan inscripción, autoría, privacidad familiar explícita, revisión y PDF local.
- Bootstrap/reload, sesiones, serializaciones, enums persistidos, índices y claves SharedPreferences no se sustituyen.
- No hay migración desde la base de datos del rediseño ni reasignación de registros ambiguos. Se mantienen los datos canónicos anteriores; no se garantiza compatibilidad de datos creados en la aplicación distinta del tercero.

## Integración visual y correcciones delimitadas

El sistema compartido ofrece tipografía incluida, tarjetas con jerarquía, formularios coherentes, superficies claras/oscuras, grillas que pasan a una columna con texto grande y estados vacíos comprensibles. Se adaptan portada, panel alumno, menú institucional, buscador, perfil institucional y accesos educativos. Las pantallas institucionales que ya utilizaban el workspace y las tarjetas heredan el estilo; sus guardas y acciones no se reemplazan.

La prueba visual encontró un defecto anterior del selector de apariencia: el widget de portada retenía el ThemeMode de la ruta inicial y repetía el primer modo. La portada ahora mantiene su selección visual y sincroniza cambios del padre; el callback existente sigue controlando la aplicación y persistencia. Se prueba el ciclo completo desde `AtenaApp`, sin crear sesión.

El buscador conserva los servicios reales. Se retira la petición de GPS y sus controles de distancia porque el modelo institucional actual no persiste coordenadas. País/provincia/localidad siguen funcionando. Se corrige el selector de modalidad para no desbordar a 320 px con texto ampliado. Los tests previos cambian exclusivamente sus localizadores de texto `Curricular` por `Educación formal`; no se relajan assertions.

## Preparación del producto público

| Dimensión | Estado y límite |
|---|---|
| Educación formal | Etiqueta pública de `curricular`. Convivencia con sala, grado, año y turno existentes. |
| Actividades y formación | Etiqueta pública de `extracurricular`; no se renombran claves ni enums. |
| Instituciones mixtas | Se conservan ambos indicadores independientes; el perfil puede mostrar ambas propuestas. |
| Universidad | Pertenece conceptualmente a formal. No se la asigna automáticamente a actividades. Faltan tipado específico y adaptación de formularios para programas/comisiones universitarias; no se anuncia ese circuito como implementado. |
| Buscar primero | Presentación y servicio de consulta preparados para separar descubrimiento de acciones personales. La entrada normal al buscador sigue siendo por perfil alumno: NO se afirma que ya sea un catálogo público anónimo. El siguiente bloque reutilizará esta misma pantalla/servicio, sin otra arquitectura. |
| Costo para el alumno | `precio` de la actividad: gratuito / con costo / consultar. No usa `tipoPlan`. Ausencia de precio no significa gratuito. Prueba con planes Free, Premium y Prueba. |
| Costo formal | Sin campo canónico suficiente: no se ofrece filtro de precio formal falso. Tampoco se inventa estatal/privada ni coordenadas. |
| Free / Premium | Diseño comercial pendiente de aprobación de límites. Separa presencia pública de gestión avanzada, sin paywalls nuevos ni restricciones destructivas. |
| Procedencia | Ficha local sin sello de verificación. No se crean instituciones ni datos para llenar resultados. |

### Frontera de responsabilidades para la próxima unidad

**Presencia pública:** ficha, contacto, dirección, oferta, horarios, requisitos, costo publicado, disponibilidad pública. Su consulta futura no dependerá del plan comercial. No debe exponer propietarios, credenciales, operadores, familias ni solicitudes.

**Gestión avanzada:** áreas, operadores, capacidades, administración, documentos, comunicaciones, seguimiento, auditoría y volumen. Los permisos continúan siendo controles de autorización, no equivalentes a una futura suscripción. No retirar funcionalidades actuales para monetizar sin un contrato comercial aprobado.

**Acción personal:** al solicitar inscripción se validarán sesión e identidad y se conservará la intención de búsqueda. Un visitante nunca se representará con un owner/perfil inventado. Login/reload/logout actuales se conservan hasta probar ese nuevo contrato.

El candidato de catálogo Supabase existente se conserva con su vocabulario interno; estas etiquetas no requieren renombrar tablas. La publicación remota, el vínculo 23514 y RLS requieren una unidad y autorización separadas. Confirmar solicitudes y consumir cupo de forma multiusuario exigirá una transacción del servidor; no se simula aquí.

## Pendientes cerrados y priorizados

### Necesarios para una V1 institucional compartida

1. Validar el APK consolidado en teléfono real conservando datos existentes y firma; aprobación visual del usuario.
2. Cerrar el diagnóstico/verificación remota de identidades y autorización sin debilitar RLS.
3. Conectar el catálogo existente y abrir descubrimiento anónimo con datos públicos explícitos, procedencia y retorno al contexto tras login.
4. Incorporar solicitudes/cupos remotos transaccionales antes de prometer sincronización entre dispositivos.
5. Completar criterios y pruebas de coste formal, estatal/privada, coordenadas y adaptación universitaria según datos realmente disponibles; no simular filtros.
6. Consolidar los cambios locales en unidades revisadas y definir límites comerciales Free/Premium sin retirar capacidades existentes.

### Mejoras futuras (fuera de esta integración)

Pagos, marketplace, chat general, publicidad, IA, rankings, métricas avanzadas, gamificación y sistema universitario completo. La traducción de los nuevos textos españoles a los idiomas secundarios también requiere revisión de producto; no se importaron las traducciones incompatibles del tercero.

## Alcance de validación

La evidencia de tests, builds, análisis, APK, hashes y Git se detalla en el informe de cierre de esta unidad. Las pruebas automatizadas no equivalen a haber utilizado un teléfono físico ni validado sincronización remota. No se tocaron Supabase ni los cuatro históricos.
