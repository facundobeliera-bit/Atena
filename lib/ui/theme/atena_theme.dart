// lib/ui/theme/atena_theme.dart
//
// Tema visual de ATENA (Material 3).
//
// - Tipografía: Plus Jakarta Sans (interfaz) + Cinzel (logotipo).
// - Un ThemeData por área (marca / alumno / institución) y brillo.
// - Las pantallas eligen su área con AtenaRoleTheme (ver widgets/atena_page.dart).

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'atena_colors.dart';
import 'atena_tokens.dart';

/// Datos de marca accesibles desde cualquier widget:
/// `Theme.of(context).extension<AtenaBrand>()!`
@immutable
class AtenaBrand extends ThemeExtension<AtenaBrand> {
  final AtenaRole role;
  final LinearGradient gradient;
  final Color canvas;
  final Color success;
  final Color warning;
  final Color info;

  const AtenaBrand({
    required this.role,
    required this.gradient,
    required this.canvas,
    required this.success,
    required this.warning,
    required this.info,
  });

  static AtenaBrand of(BuildContext context) =>
      Theme.of(context).extension<AtenaBrand>() ??
      AtenaBrand(
        role: AtenaRole.brand,
        gradient: AtenaColors.brandGradient,
        canvas: AtenaColors.canvas(Theme.of(context).brightness),
        success: AtenaColors.success,
        warning: AtenaColors.warning,
        info: AtenaColors.info,
      );

  @override
  AtenaBrand copyWith({
    AtenaRole? role,
    LinearGradient? gradient,
    Color? canvas,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AtenaBrand(
      role: role ?? this.role,
      gradient: gradient ?? this.gradient,
      canvas: canvas ?? this.canvas,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AtenaBrand lerp(ThemeExtension<AtenaBrand>? other, double t) {
    if (other is! AtenaBrand) return this;
    return AtenaBrand(
      role: t < 0.5 ? role : other.role,
      gradient: LinearGradient.lerp(gradient, other.gradient, t) ?? gradient,
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}

class AtenaTheme {
  const AtenaTheme._();

  static const String fontFamily = 'PlusJakartaSans';
  static const String displayFontFamily = 'Cinzel';

  static final Map<String, ThemeData> _cache = <String, ThemeData>{};

  static ThemeData light([AtenaRole role = AtenaRole.brand]) =>
      of(role, Brightness.light);

  static ThemeData dark([AtenaRole role = AtenaRole.brand]) =>
      of(role, Brightness.dark);

  static ThemeData of(AtenaRole role, Brightness brightness) {
    final key = '${role.name}-${brightness.name}';
    return _cache.putIfAbsent(key, () => _build(role, brightness));
  }

  static TextTheme _textTheme(ColorScheme cs) {
    const f = fontFamily;
    final strong = cs.onSurface;
    final soft = cs.onSurfaceVariant;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: f,
        fontSize: 52,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: strong,
      ),
      displayMedium: TextStyle(
        fontFamily: f,
        fontSize: 42,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: strong,
      ),
      displaySmall: TextStyle(
        fontFamily: f,
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: strong,
      ),
      headlineLarge: TextStyle(
        fontFamily: f,
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: strong,
      ),
      headlineMedium: TextStyle(
        fontFamily: f,
        fontSize: 26,
        height: 1.22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: strong,
      ),
      headlineSmall: TextStyle(
        fontFamily: f,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: strong,
      ),
      titleLarge: TextStyle(
        fontFamily: f,
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: strong,
      ),
      titleMedium: TextStyle(
        fontFamily: f,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: strong,
      ),
      titleSmall: TextStyle(
        fontFamily: f,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: strong,
      ),
      bodyLarge: TextStyle(
        fontFamily: f,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: strong,
      ),
      bodyMedium: TextStyle(
        fontFamily: f,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: strong,
      ),
      bodySmall: TextStyle(
        fontFamily: f,
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: soft,
      ),
      labelLarge: TextStyle(
        fontFamily: f,
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: strong,
      ),
      labelMedium: TextStyle(
        fontFamily: f,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: strong,
      ),
      labelSmall: TextStyle(
        fontFamily: f,
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: soft,
      ),
    );
  }

  static ThemeData _build(AtenaRole role, Brightness brightness) {
    final cs = AtenaColors.scheme(role, brightness);
    final dark = brightness == Brightness.dark;
    final text = _textTheme(cs);
    final canvas = AtenaColors.canvas(brightness);
    final fieldFill = dark ? cs.surfaceContainer : cs.surfaceContainerLow;

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AtenaRadius.field,
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = const RoundedRectangleBorder(
      borderRadius: AtenaRadius.button,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      fontFamily: fontFamily,
      textTheme: text,
      primaryTextTheme: text.apply(
        bodyColor: cs.onPrimary,
        displayColor: cs.onPrimary,
      ),
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[
        AtenaBrand(
          role: role,
          gradient: AtenaColors.roleGradient(role),
          canvas: canvas,
          success: dark ? const Color(0xFF4ADE80) : AtenaColors.success,
          warning: dark ? const Color(0xFFFBBF24) : AtenaColors.warning,
          info: dark ? const Color(0xFF38BDF8) : AtenaColors.info,
        ),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: canvas,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 64,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        iconTheme: IconThemeData(color: cs.onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 24),
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AtenaRadius.card,
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        // Los ElevatedButton se usan como acción principal: mismo look que Filled.
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.10),
          disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          side: BorderSide(color: cs.outline, width: 1.2),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        extendedTextStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: fieldFill,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: fieldBorder(cs.outlineVariant),
        enabledBorder: fieldBorder(cs.outlineVariant),
        disabledBorder: fieldBorder(cs.outlineVariant.withValues(alpha: 0.5)),
        focusedBorder: fieldBorder(cs.primary, 1.8),
        errorBorder: fieldBorder(cs.error, 1.2),
        focusedErrorBorder: fieldBorder(cs.error, 1.8),
        labelStyle: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: text.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.75),
        ),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: cs.error),
        helperMaxLines: 3,
        errorMaxLines: 3,
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surface,
        selectedColor: cs.primaryContainer,
        disabledColor: cs.surfaceContainer,
        side: BorderSide(color: cs.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: AtenaRadius.chip),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: cs.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        checkmarkColor: cs.onPrimaryContainer,
        iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 18),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        titleTextStyle: text.titleSmall?.copyWith(fontSize: 15),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AtenaRadius.md)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        contentTextStyle: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        modalBackgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: cs.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        actionTextColor: cs.inversePrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        width: null,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontSize: 12,
            letterSpacing: 0.1,
            color: selected ? cs.onSurface : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        selectedIconTheme: IconThemeData(color: cs.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: text.labelLarge?.copyWith(fontSize: 14),
        unselectedLabelStyle: text.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: cs.outlineVariant,
        overlayColor: WidgetStatePropertyAll(
          cs.primary.withValues(alpha: 0.06),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          side: BorderSide(color: cs.outlineVariant),
          selectedBackgroundColor: cs.primaryContainer,
          selectedForegroundColor: cs.onPrimaryContainer,
          textStyle: text.labelMedium,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        side: BorderSide(color: cs.outline, width: 1.6),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Icon(Icons.check_rounded, size: 16)
              : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primaryContainer,
        linearMinHeight: 6,
        borderRadius: const BorderRadius.all(Radius.circular(99)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: text.bodySmall?.copyWith(color: cs.onInverseSurface),
        waitDuration: const Duration(milliseconds: 400),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: cs.outlineVariant),
        ),
        textStyle: text.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cs.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              side: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cs.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              side: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: cs.primary,
        headerForegroundColor: cs.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        dayStyle: text.bodyMedium,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: cs.error,
        textColor: cs.onError,
        textStyle: text.labelSmall?.copyWith(color: cs.onError, fontSize: 10.5),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: cs.primary,
        collapsedIconColor: cs.onSurfaceVariant,
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
        thumbColor: WidgetStatePropertyAll(
          cs.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: cs.primary,
        selectionColor: cs.primary.withValues(alpha: 0.25),
        selectionHandleColor: cs.primary,
      ),
    );
  }
}
