# ATENA · Plataforma educativa

ATENA conecta a **familias y alumnos** con **instituciones educativas** (escuelas, jardines, institutos, clubes y academias). Las instituciones publican sus vacantes y las familias las encuentran, piden su lugar y siguen cada trámite desde el teléfono o la computadora.

App multiplataforma hecha con Flutter: **Android, iOS, web (PWA), Windows, macOS y Linux**, en **español, inglés y portugués**, con modo claro y oscuro.

---

## Funcionalidades

### Familias y alumnos
- Cuenta familiar con **varios alumnos** (hijos/as) y selector de alumno.
- **Explorar instituciones**: búsqueda sin tildes por nombre o ciudad, filtros por nivel, actividad extracurricular y modalidad, y vacantes disponibles para la edad del alumno.
- **Ficha pública** de cada institución: fotos, descripción, servicios, horarios y contacto directo (teléfono, WhatsApp, email, web, redes).
- **Pedir vacante** en un curso, sala o actividad, con mensaje opcional.
- **Mis solicitudes**: estado en tiempo real, historial de cada cambio, cancelación y comprobante en PDF.
- **Calendario**: eventos de las instituciones (reuniones, actos, exámenes, vacaciones), confirmación de asistencia y notas personales.
- **Documentos**: la institución pide un documento y la familia lo sube como PDF o foto; ve si fue aprobado o si hay que corregirlo.
- **Notificaciones** con acceso directo a cada trámite.
- **Ficha del alumno** con foto, datos personales y exportación a PDF.

### Instituciones
- Registro en dos pasos (datos + plan) y **panel** con indicadores, guía de primeros pasos y accesos rápidos.
- **Vacantes**: cursos curriculares por nivel y actividades extracurriculares por bloque, con cupo, turno, horario, días, edades y arancel; pausar, duplicar y ver ocupación.
- **Solicitudes**: revisión con los datos del alumno, confirmación (con control de cupo) o rechazo con motivo, baja de alumnos y pedido de documentos.
- **Alumnos**: listado por curso con búsqueda y exportación a PDF.
- **Comunicaciones**: eventos en el calendario de las familias (con confirmación de asistencia) y avisos masivos por curso.
- **Documentación**: pedidos, revisión de archivos recibidos y aprobación o corrección.
- **Croquis de aula**: distribución de bancos con los alumnos confirmados y exportación a PDF.
- **Perfil público** (logo, fotos, servicios, contacto) con vista previa e indicador de completitud.
- **Plan**: niveles y módulos contratados, precio mensual, código promocional y prueba de 30 días.

### Para todos
- Preferencias de idioma y apariencia, sección de privacidad y borrado de datos del dispositivo.
- **Eliminar cuenta** desde el menú del inicio (lo exigen Apple y Google): pide la contraseña, borra todo lo asociado y avisa a la otra parte de los trámites que quedan sin efecto.
- **Datos de ejemplo** (en una instalación nueva, desde la portada): tres instituciones con vacantes y una familia con dos alumnos. Contraseña de todas las cuentas: `demo1234`.
  - Familia: `familia@demo.com`
  - Instituciones: `colegio@demo.com`, `jardin@demo.com`, `club@demo.com`

  Son útiles para demostraciones comerciales y como **cuentas de prueba para la revisión de Apple y Google**.

---

## Identidad visual

| Elemento | Valor |
|---|---|
| Emblema | Casco de Atenea con birrete y laureles — `assets/brand/atena_mark.png` (blanco, se colorea en la app) |
| Logotipo | "ATENA" en **Cinzel** |
| Tipografía de interfaz | **Plus Jakarta Sans** |
| Familias / alumnos | Azul `#2563EB` |
| Marca | Índigo `#4F46E5` |
| Instituciones | Violeta `#7C3AED` |
| Destacados | Dorado laurel `#F5B83D` |

- Sistema de diseño: `lib/ui/` (tema, colores, componentes, estados vacíos y de error, avisos).
- Íconos de la app y pantallas de carga ya generados para todas las plataformas. Las imágenes fuente están en `branding/`.
- Fuentes bajo licencia SIL Open Font License (`assets/fonts/OFL-*.txt`).

---

## Requisitos

- Flutter **3.47** (canal stable) con Dart 3.13.
- Android: Android Studio y SDK. iOS/macOS: Xcode en una Mac. Windows: Visual Studio con "Desarrollo para el escritorio con C++".

```bash
flutter pub get
flutter run            # elegí el dispositivo
flutter test           # pruebas automáticas
```

---

## Compilar y publicar

### Web
```bash
flutter build web --release
```
Publicá el contenido de `build/web` en cualquier hosting estático (Firebase Hosting, Netlify, Vercel, nginx). Es una PWA instalable.

### Android (Google Play)
1. Creá la clave de firma (una sola vez y guardala en un lugar seguro):
   ```bash
   keytool -genkey -v -keystore atena-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias atena
   ```
2. Creá `android/key.properties` (no se sube al repositorio):
   ```properties
   storePassword=********
   keyPassword=********
   keyAlias=atena
   storeFile=/ruta/a/atena-release.jks
   ```
3. Generá el paquete: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.

### iOS (App Store)
1. En una Mac: `open ios/Runner.xcworkspace`, seleccioná tu equipo (Signing & Capabilities).
2. `flutter build ipa --release` y subí con Transporter o Xcode.

### Windows / macOS / Linux
```bash
flutter build windows --release   # build/windows/x64/runner/Release/atena.exe
flutter build macos --release
flutter build linux --release
```

### Identificadores
- Android / iOS / macOS / Linux: **`com.atenaeducacion.app`**
- Nombre visible: **ATENA** · Versión: `pubspec.yaml` (`1.0.0+1`) y `lib/app_info.dart`.

> Confirmá el identificador antes de la primera publicación: después no se puede cambiar.

---

## Arquitectura

```
lib/
  main.dart                  Arranque, tema, idiomas
  app_info.dart              Versión publicada
  core/                      Capa de datos y reglas de negocio
    store/atena_store.dart   Almacenamiento (colecciones JSON locales)
    models/                  Oferta, Solicitud, Notificacion, Evento, Documento, Croquis…
    repos/                   Instituciones, Ofertas, Solicitudes, Notificaciones,
                             Calendario y avisos, Documentos, Croquis, Alumnos
    demo/                    Datos de ejemplo
  models/                    Cuenta y perfiles, institución y plan, bloques extracurriculares
  services/                  Cuentas, acceso, sesión, contraseñas (PBKDF2), preferencias
  routes/                    Puerta de sesión, rutas y navegación de alto nivel
  ui/                        Sistema de diseño, textos de dominio y formatos
  screens/                   Pantallas: auth, landing, cuentas, alumno(s), instituciones, comunes
  pdf/                       Documentos PDF con la marca
  l10n/                      Textos en es (base), en y pt
```

Principios:
- Las pantallas solo hablan con `lib/core` (repositorios) y `AuthService`; ninguna toca el almacenamiento directamente.
- Las reglas de negocio están en los repositorios y tienen pruebas: cupos, solicitudes duplicadas, transiciones de estado, permisos y notificaciones a ambas partes.
- Los errores tienen código (`AtenaException`, `AuthException`) y la interfaz los traduce; nunca se muestran datos técnicos.

---

## Datos y privacidad

**Importante — alcance de esta versión:** toda la información se guarda **en el dispositivo** (almacenamiento local del sistema o del navegador). Esto significa que:

- Una familia y una institución solo comparten información si usan el **mismo dispositivo o navegador**. Para que interactúen desde dispositivos distintos hace falta un **servidor** (backend).
- La recuperación de contraseña se valida con el DNI de un alumno de la cuenta (familias) o el CUIT (instituciones), porque no hay envío de emails.
- Los archivos (fotos y documentos) tienen límites de tamaño, y en web dependen del espacio que dé el navegador.

**Camino a un servicio en la nube:** la persistencia está concentrada en `lib/core/store/atena_store.dart` y la autenticación en `lib/services/auth_service.dart`. Reemplazar esas dos piezas por un backend (por ejemplo Firebase o Supabase: autenticación con email, base de datos, almacenamiento de archivos y notificaciones push) habilita el uso entre dispositivos sin rehacer las pantallas.

Las contraseñas se guardan con **PBKDF2-HMAC-SHA256** y sal aleatoria; las cuentas creadas con versiones anteriores se migran solas al ingresar.

---

## Traducciones

- Archivos: `lib/l10n/app_es.arb` (base), `app_en.arb`, `app_pt.arb`.
- Después de editarlos: `flutter gen-l10n`.
- `lib/l10n/untranslated.txt` lista los textos que falten traducir (debe quedar vacío).

---

## Pruebas

```bash
flutter test
```
171 pruebas en `test/`:

| Archivo | Qué cubre |
|---|---|
| `auth_test.dart` | Contraseñas, registro, ingreso, restablecimiento y sesión |
| `core_test.dart` | Reglas de vacantes y solicitudes, notificaciones, calendario, avisos, documentos y buscador |
| `baja_test.dart` | Eliminar cuenta de familia y de institución |
| `demo_test.dart` | Datos de ejemplo |
| `pdf_test.dart` | Los cuatro documentos PDF |
| `app_flow_test.dart` | Bienvenida → registro → inicio → cerrar sesión |
| `pantallas_*_test.dart` | Cada pantalla de familias e instituciones, en teléfono y escritorio, claro y oscuro, en los tres idiomas |

No cubren lo que depende del dispositivo: cámara, selector de archivos, compartir e imprimir. Eso hay que probarlo a mano en un teléfono.

---

## Antes de publicar

La guía completa, con los textos de la ficha en los tres idiomas, las respuestas a los formularios de privacidad y las notas para revisión, está en [docs/publicacion-en-tiendas.md](docs/publicacion-en-tiendas.md).

- [ ] Confirmar el identificador `com.atenaeducacion.app` (o cambiarlo) y la marca registrada.
- [ ] Crear la clave de firma de Android y configurar el equipo de Apple.
- [ ] Completar y publicar la política de privacidad en una URL (borrador en [docs/politica-de-privacidad.md](docs/politica-de-privacidad.md)); las tiendas la exigen.
- [ ] Cargar la ficha: textos, ícono, gráfico y capturas (en `branding/tiendas/`).
- [ ] Definir el medio de cobro del plan (la app hoy no procesa pagos: las instituciones quedan en prueba de 30 días).
- [ ] Revisar precios y código promocional en `lib/screens/instituciones/widgets/pln_precios.dart`. El código y su cupo de 100 usos se validan en el dispositivo: sirve como cortesía de lanzamiento, pero un cupo real necesita el servidor.
- [ ] Si se necesita uso entre dispositivos, implementar el backend (ver "Datos y privacidad").
