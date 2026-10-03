// lib/screens/alumnos/widgets/explorar_contacto.dart
//
// ATENA – Contacto de la institución: arma los enlaces (teléfono, WhatsApp,
// email, sitio web, redes y mapa) a partir del perfil público y los abre con
// la aplicación que corresponda en el dispositivo.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/atena_ui.dart';

class ExplorarContactoLink {
  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;
  final Uri uri;

  const ExplorarContactoLink({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
    required this.uri,
  });
}

/// Enlaces de contacto disponibles. Se omiten los vacíos o inválidos.
List<ExplorarContactoLink> explorarLinksContacto(
  AppLocalizations t,
  PerfilPublico p, {
  String direccion = '',
}) {
  final links = <ExplorarContactoLink>[];

  void agregar(
    IconData icono,
    Color color,
    String titulo,
    String valor,
    Uri? uri,
  ) {
    final v = valor.trim();
    if (uri == null || v.isEmpty) return;
    links.add(
      ExplorarContactoLink(
        icono: icono,
        color: color,
        titulo: titulo,
        valor: v,
        uri: uri,
      ),
    );
  }

  agregar(
    Icons.call_rounded,
    AtenaColors.success,
    t.explorarLlamar,
    p.telefono,
    _telefono(p.telefono),
  );
  agregar(
    Icons.chat_rounded,
    AtenaColors.success,
    t.explorarWhatsapp,
    p.whatsapp,
    _whatsapp(p.whatsapp),
  );
  agregar(
    Icons.mail_rounded,
    AtenaColors.info,
    t.commonEmail,
    p.email,
    _email(p.email),
  );
  agregar(
    Icons.language_rounded,
    AtenaColors.indigo,
    t.explorarSitioWeb,
    _sinEsquema(p.sitioWeb),
    _web(p.sitioWeb),
  );
  agregar(
    Icons.photo_camera_rounded,
    AtenaColors.violet,
    t.explorarInstagram,
    _visible(p.instagram),
    _red(p.instagram, const ['instagram.com'], 'https://www.instagram.com/'),
  );
  agregar(
    Icons.facebook_rounded,
    AtenaColors.blue,
    t.explorarFacebook,
    _visible(p.facebook),
    _red(p.facebook, const [
      'facebook.com',
      'fb.com',
    ], 'https://www.facebook.com/'),
  );
  agregar(
    Icons.smart_display_rounded,
    AtenaColors.danger,
    t.explorarYoutube,
    _visible(p.youtube),
    _red(p.youtube, const [
      'youtube.com',
      'youtu.be',
    ], 'https://www.youtube.com/@'),
  );
  agregar(
    Icons.directions_rounded,
    AtenaColors.goldDeep,
    t.explorarComoLlegar,
    direccion,
    _mapa(direccion),
  );
  return links;
}

String _digitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

Uri? _telefono(String s) {
  final limpio = s.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  if (_digitos(limpio).length < 6) return null;
  return Uri(scheme: 'tel', path: limpio);
}

Uri? _whatsapp(String s) {
  final d = _digitos(s);
  if (d.length < 8) return null;
  return Uri.https('wa.me', '/$d');
}

Uri? _email(String s) {
  final v = s.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return null;
  return Uri(scheme: 'mailto', path: v);
}

final RegExp _esquema = RegExp(r'^https?://', caseSensitive: false);

Uri? _web(String s) {
  var v = s.trim();
  if (v.isEmpty || v.contains(' ')) return null;
  if (!_esquema.hasMatch(v)) v = 'https://$v';
  final uri = Uri.tryParse(v);
  if (uri == null || !uri.host.contains('.')) return null;
  return uri;
}

String _sinEsquema(String s) {
  var v = s.trim().replaceFirst(_esquema, '');
  if (v.startsWith('www.')) v = v.substring(4);
  return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
}

/// Redes: acepta "@usuario", "usuario" o la dirección completa del perfil.
Uri? _red(String s, List<String> dominios, String base) {
  final v = s.trim();
  if (v.isEmpty) return null;
  final lower = v.toLowerCase();
  if (dominios.any(lower.contains)) return _web(v);
  final usuario = v.replaceFirst(RegExp(r'^@+'), '');
  if (usuario.isEmpty || usuario.contains(RegExp(r'[\s/]'))) return null;
  return Uri.tryParse('$base${Uri.encodeComponent(usuario)}');
}

/// Cómo se muestra el usuario o la dirección de una red.
String _visible(String s) {
  final v = s.trim();
  if (v.isEmpty) return '';
  if (v.contains('.') && v.contains('/')) return _sinEsquema(v);
  return v.startsWith('@') ? v : '@$v';
}

Uri? _mapa(String direccion) {
  final v = direccion.trim();
  if (v.isEmpty) return null;
  return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': v});
}

/// Abre el enlace con la aplicación correspondiente; avisa si no se pudo.
Future<void> explorarAbrirEnlace(BuildContext context, Uri uri) async {
  final t = AppLocalizations.of(context);
  final web = uri.scheme == 'http' || uri.scheme == 'https';
  try {
    final ok = await launchUrl(
      uri,
      mode: web ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
    if (!ok && context.mounted) {
      AtenaFeedback.error(context, t.explorarNoSePudoAbrir);
    }
  } catch (_) {
    if (context.mounted) AtenaFeedback.error(context, t.explorarNoSePudoAbrir);
  }
}

/// Tarjeta con las vías de contacto (cada fila abre su enlace).
class ExplorarContactoCard extends StatelessWidget {
  final List<ExplorarContactoLink> links;

  const ExplorarContactoCard({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AtenaCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < links.length; i++) ...[
            if (i > 0) const Divider(indent: 70, endIndent: 16),
            ListTile(
              leading: AtenaIconBadge(
                icon: links[i].icono,
                color: links[i].color,
                size: 40,
              ),
              title: Text(links[i].titulo),
              subtitle: Text(
                links[i].valor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              onTap: () => explorarAbrirEnlace(context, links[i].uri),
            ),
          ],
        ],
      ),
    );
  }
}
