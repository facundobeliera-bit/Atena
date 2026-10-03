// lib/ui/widgets/atena_avatar.dart
//
// Avatar con foto (si existe) o iniciales sobre el gradiente del área.
// Las fotos se guardan como texto base64 (con o sin prefijo "b64:").

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/atena_theme.dart';

/// Decodifica una referencia de imagen guardada como base64 ("b64:..." o crudo).
Uint8List? atenaDecodeImageRef(String? ref) {
  var s = (ref ?? '').trim();
  if (s.isEmpty) return null;
  if (s.startsWith('b64:')) s = s.substring(4);
  final comma = s.indexOf(',');
  if (s.startsWith('data:') && comma > 0) s = s.substring(comma + 1);
  try {
    final bytes = base64Decode(s);
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}

class AtenaAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageRef;
  final Uint8List? imageBytes;
  final IconData fallbackIcon;
  final bool ring;

  const AtenaAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.imageRef,
    this.imageBytes,
    this.fallbackIcon = Icons.person_rounded,
    this.ring = false,
  });

  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'[\s,]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final brand = AtenaBrand.of(context);
    final bytes = imageBytes ?? atenaDecodeImageRef(imageRef);

    final content = bytes != null
        ? Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                _fallback(initialsOf(name), brand),
          )
        : _fallback(initialsOf(name), brand);

    final avatar = ClipOval(
      child: SizedBox(width: size, height: size, child: content),
    );

    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
      child: avatar,
    );
  }

  Widget _fallback(String initials, AtenaBrand brand) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: brand.gradient),
      child: Center(
        child: initials.isEmpty
            ? Icon(fallbackIcon, color: Colors.white, size: size * 0.5)
            : Text(
                initials,
                style: TextStyle(
                  fontFamily: AtenaTheme.fontFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.38,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
