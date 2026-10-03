# Publicar ATENA en Google Play y App Store

Guía para quien suba la app a las tiendas: textos de la ficha listos para copiar, respuestas a los formularios de privacidad y notas para el equipo de revisión. Los pasos de compilación y firma están en el [README](../README.md#compilar-y-publicar).

## 1. Datos de la ficha

| Campo | Valor |
|---|---|
| Nombre | ATENA |
| Categoría | Educación |
| Identificador | `com.atenaeducacion.app` (confirmarlo antes de la primera subida: no se puede cambiar) |
| Versión | 1.0.0 (compilación 1) |
| Idiomas | Español (principal), inglés y portugués |
| Precio de descarga | Gratis |
| Contacto de soporte | `[email]` · `[sitio web]` |
| Política de privacidad | `[URL donde publiques docs/politica-de-privacidad.md]` |

### Español (principal)

**Subtítulo (App Store, máx. 30):** Vacantes y trámites escolares

**Descripción breve (Google Play, máx. 80):** Encontrá instituciones, pedí vacantes y seguí cada trámite escolar.

**Palabras clave (App Store, máx. 100):** escuela,colegio,vacantes,inscripción,jardín,alumnos,familias,educación,documentos,calendario

**Descripción completa:**

```
ATENA conecta a las familias con escuelas, jardines, institutos, clubes y academias.

PARA FAMILIAS Y ALUMNOS
• Explorá instituciones por nombre, ciudad, nivel o actividad, y mirá su perfil con fotos, horarios y contacto.
• Pedí una vacante en un curso, sala o actividad en pocos pasos.
• Seguí el estado de cada solicitud y guardá el comprobante en PDF.
• Recibí los eventos de la institución en tu calendario y confirmá asistencia.
• Enviá los documentos que te piden como PDF o foto, y enterate cuando se aprueban.
• Una sola cuenta para todos tus hijos.

PARA INSTITUCIONES
• Publicá tus cursos y actividades con cupo, turno, horario, edades y arancel.
• Revisá las solicitudes, confirmá o rechazá con un mensaje y controlá los cupos automáticamente.
• Llevá el listado de alumnos por curso y exportalo a PDF.
• Comunicá eventos y avisos a todas las familias o a un curso.
• Pedí documentación y revisala desde un solo lugar.
• Armá el croquis de cada aula y mostrá tu institución con un perfil público.

PENSADA PARA SER SIMPLE
• En español, inglés y portugués.
• Modo claro y oscuro.
• Tus datos se guardan en tu dispositivo: sin publicidad ni seguimiento.
```

### English

**Subtitle (max 30):** School openings and paperwork

**Short description (max 80):** Find schools, request a spot and follow every step of enrolment.

**Keywords (max 100):** school,enrolment,admissions,kindergarten,students,families,education,documents,calendar,club

**Full description:**

```
ATENA connects families with schools, kindergartens, institutes, clubs and academies.

FOR FAMILIES AND STUDENTS
• Explore institutions by name, city, level or activity, and see their profile with photos, hours and contact details.
• Request a spot in a course, class or activity in a few steps.
• Follow the status of every request and keep the receipt as a PDF.
• Get the institution's events in your calendar and confirm attendance.
• Send the documents you are asked for as a PDF or photo, and know when they are approved.
• One account for all your children.

FOR INSTITUTIONS
• Publish your courses and activities with capacity, shift, schedule, ages and fees.
• Review requests, accept or decline with a message, and keep capacity under control automatically.
• Keep the student list for each course and export it to PDF.
• Share events and announcements with every family or with one course.
• Request paperwork and review it in one place.
• Draw each classroom's seating plan and present your institution with a public profile.

DESIGNED TO BE SIMPLE
• In Spanish, English and Portuguese.
• Light and dark mode.
• Your data stays on your device: no ads, no tracking.
```

### Português

**Subtítulo (máx. 30):** Vagas e trâmites escolares

**Descrição breve (máx. 80):** Encontre instituições, peça uma vaga e acompanhe cada trâmite escolar.

**Palavras-chave (máx. 100):** escola,colégio,vagas,matrícula,creche,alunos,famílias,educação,documentos,calendário

**Descrição completa:**

```
A ATENA conecta as famílias com escolas, creches, institutos, clubes e academias.

PARA FAMÍLIAS E ALUNOS
• Explore instituições por nome, cidade, nível ou atividade e veja o perfil com fotos, horários e contato.
• Peça uma vaga em um curso, turma ou atividade em poucos passos.
• Acompanhe o status de cada solicitação e guarde o comprovante em PDF.
• Receba os eventos da instituição no seu calendário e confirme presença.
• Envie os documentos solicitados em PDF ou foto e saiba quando forem aprovados.
• Uma única conta para todos os seus filhos.

PARA INSTITUIÇÕES
• Publique seus cursos e atividades com vagas, turno, horário, idades e mensalidade.
• Analise as solicitações, aceite ou recuse com uma mensagem e controle as vagas automaticamente.
• Mantenha a lista de alunos por curso e exporte para PDF.
• Comunique eventos e avisos a todas as famílias ou a uma turma.
• Solicite documentação e revise tudo em um só lugar.
• Monte o mapa de cada sala e apresente sua instituição com um perfil público.

FEITA PARA SER SIMPLES
• Em espanhol, inglês e português.
• Modo claro e escuro.
• Seus dados ficam no seu dispositivo: sem anúncios nem rastreamento.
```

## 2. Imágenes

| Recurso | Dónde está |
|---|---|
| Ícono 1024×1024 (App Store) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` |
| Ícono 512×512 (Google Play) | `branding/tiendas/icono_512.png` |
| Gráfico de funciones 1024×500 (Google Play) | `branding/tiendas/grafico_funciones_1024x500.png` |
| Capturas de teléfono 1290×2796 | `branding/tiendas/capturas/` |
| Fuentes del ícono y del emblema | `branding/` |

Las 10 capturas se tomaron con los datos de ejemplo, en español y modo claro. Sirven para iPhone de 6,7" y para Google Play; para iPad hay que tomarlas en un iPad o simulador (2064×2752).

## 3. Privacidad y seguridad de los datos

La versión 1.0 guarda todo en el dispositivo y no transmite información. Con eso, las respuestas son:

**App Store → Privacidad de la app**
- ¿Recopilás datos de esta app? → **No** ("Data Not Collected").

**Google Play → Seguridad de los datos**
- ¿La app recopila o comparte alguno de los tipos de datos de usuario requeridos? → **No**. Los datos que se procesan solo en el dispositivo y no se envían fuera de él no cuentan como recopilados.
- Creación de cuentas: la app permite crear cuentas, que existen solo en el dispositivo. Si el formulario pide una URL para eliminar la cuenta, usá la de la política de privacidad, sección "Cuánto tiempo se conserva y cómo se elimina", que explica el camino dentro de la app.

**Otras declaraciones**
- Anuncios: **no** contiene.
- Cifrado (App Store): la app solo usa funciones de resumen para proteger contraseñas; `ITSAppUsesNonExemptEncryption` ya está en `false`.
- Público objetivo (Google Play): se recomienda **18 años o más**, porque las cuentas las administran personas adultas (familias y personal de instituciones). Elegir edades menores activa los requisitos del programa para familias.
- Clasificación de contenido: sin contenido sensible; el cuestionario da la clasificación más baja ("Para todos" / "4+").

> Estas respuestas valen mientras la app no envíe datos a un servidor. Si se agrega un backend, analítica o publicidad, hay que rehacer ambos formularios y actualizar la política.

## 4. Notas para el equipo de revisión

Texto para pegar en "Notas para la revisión" (App Store) y en "Acceso a la app" (Google Play):

```
ATENA stores all data locally on the device. No server account is needed.

To review with sample data:
1. Open the app on a fresh install. On the first screen tap "Probar con datos de ejemplo" (Try with sample data) and confirm. The link is only shown while no institution exists on the device.
2. Choose "Entrar como familia" (family side) or "Entrar como el colegio" (institution side).

Sample accounts (password for all: demo1234):
- Family: familia@demo.com
- Institutions: colegio@demo.com, jardin@demo.com, club@demo.com

Account deletion: Home screen > "Más opciones" (three-dot menu) > "Eliminar cuenta".
The app language can be changed from the settings icon on any screen (Spanish, English, Portuguese).
The app does not process payments: institutions get a 30-day trial and no purchase is offered.
```

## 5. Lista de control

- [ ] Identificador confirmado y nombre "ATENA" disponible en ambas tiendas.
- [ ] Cuenta de desarrollador de Google Play y de Apple activas.
- [ ] Clave de firma de Android creada y guardada con copia de seguridad.
- [ ] Política de privacidad publicada en una URL pública.
- [ ] Email de soporte activo.
- [ ] Ficha completa en los tres idiomas, con capturas.
- [ ] Formularios de privacidad y clasificación de contenido respondidos.
- [ ] Prueba interna (Google Play) o TestFlight (Apple) en un teléfono real antes de enviar a revisión.
- [ ] Definir cómo se cobra el plan de las instituciones antes de ofrecerlo como pago (ver README, "Antes de publicar").
