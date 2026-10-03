// lib/ui/widgets/atena_page.dart
//
// Estructura de página:
// - AtenaRoleTheme: aplica el acento del área (alumno / institución / marca).
// - AtenaScaffold: Scaffold con fondo de marca y app bar integrada.
// - AtenaContent / atenaPagePadding: centran el contenido con ancho máximo
//   (cómodo en teléfono y prolijo en escritorio).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/atena_colors.dart';
import '../theme/atena_theme.dart';
import '../theme/atena_tokens.dart';
import 'atena_backdrop.dart';

class AtenaRoleTheme extends StatelessWidget {
  final AtenaRole role;
  final Widget child;

  const AtenaRoleTheme({super.key, required this.role, required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Theme(data: AtenaTheme.of(role, brightness), child: child);
  }
}

/// Padding horizontal que centra el contenido en pantallas anchas.
EdgeInsets atenaPagePadding(
  BuildContext context, {
  double maxWidth = AtenaLayout.content,
  double top = AtenaSpace.xs,
  double bottom = AtenaSpace.xxl,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = math.max(AtenaSpace.page, (width - maxWidth) / 2);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

class AtenaScaffold extends StatelessWidget {
  final AtenaRole role;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool backdrop;
  final double backdropIntensity;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  const AtenaScaffold({
    super.key,
    this.role = AtenaRole.brand,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backdrop = true,
    this.backdropIntensity = 1,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return AtenaRoleTheme(
      role: role,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scaffold = Scaffold(
            backgroundColor: backdrop ? Colors.transparent : null,
            appBar: appBar,
            body: body,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            bottomNavigationBar: bottomNavigationBar,
            bottomSheet: bottomSheet,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          );

          if (!backdrop) return scaffold;

          return AtenaBackdrop(
            intensity: backdropIntensity,
            child: AppBarTheme(
              data: theme.appBarTheme.copyWith(
                backgroundColor: Colors.transparent,
              ),
              child: scaffold,
            ),
          );
        },
      ),
    );
  }
}

/// Centra y limita el ancho de un contenido no desplazable.
class AtenaContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const AtenaContent({
    super.key,
    required this.child,
    this.maxWidth = AtenaLayout.content,
    this.padding = const EdgeInsets.symmetric(horizontal: AtenaSpace.page),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// AppBar estándar de ATENA (título + subtítulo opcional).
class AtenaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const AtenaAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = (subtitle ?? '').trim();

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions == null
          ? null
          : [...actions!, const SizedBox(width: AtenaSpace.xs)],
      bottom: bottom,
      title: sub.isEmpty
          ? Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
