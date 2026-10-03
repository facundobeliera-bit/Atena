// lib/ui/theme/atena_tokens.dart
//
// Medidas compartidas: espaciado, radios, anchos máximos y animaciones.
// Usar siempre estos valores para mantener el ritmo visual consistente.

import 'package:flutter/widgets.dart';

class AtenaSpace {
  const AtenaSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Margen lateral estándar de las páginas.
  static const double page = 20;
}

class AtenaRadius {
  const AtenaRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(10));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AtenaLayout {
  const AtenaLayout._();

  /// Ancho máximo del contenido de lectura/formularios.
  static const double narrow = 560;

  /// Ancho máximo de pantallas con listas y tableros.
  static const double content = 920;

  /// Ancho máximo de tableros amplios.
  static const double wide = 1200;

  /// A partir de este ancho se usa el diseño de escritorio.
  static const double desktopBreakpoint = 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}

class AtenaMotion {
  const AtenaMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve curve = Curves.easeOutCubic;
}
