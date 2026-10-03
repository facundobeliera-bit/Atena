// lib/pdf/src/pdf_recursos.dart
//
// Recursos de marca de los PDF: tipografías (Plus Jakarta Sans y Cinzel) y el
// emblema de ATENA. Se cargan una sola vez y se reutilizan en cada documento.
// También adapta los textos a los glifos disponibles en la tipografía, para
// que un emoji o una letra poco común nunca se vea como un recuadro vacío.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Imagen decodificada: píxeles RGBA sin premultiplicar.
class _Raster {
  const _Raster(this.rgba, this.ancho, this.alto);

  final Uint8List rgba;
  final int ancho;
  final int alto;

  /// Copia con todos los píxeles del color indicado (conserva la transparencia).
  _Raster coloreado(PdfColor color) {
    final r = (color.red * 255).round();
    final g = (color.green * 255).round();
    final b = (color.blue * 255).round();
    final salida = Uint8List.fromList(rgba);
    for (var i = 0; i + 3 < salida.length; i += 4) {
      salida[i] = r;
      salida[i + 1] = g;
      salida[i + 2] = b;
    }
    return _Raster(salida, ancho, alto);
  }

  pw.ImageProvider imagen() =>
      pw.RawImage(bytes: rgba, width: ancho, height: alto);
}

class PdfRecursos {
  PdfRecursos._({
    required this.regular,
    required this.semiBold,
    required this.bold,
    required this.cinzel,
    required Set<int> glifos,
    _Raster? emblemaBlanco,
    _Raster? emblemaMarca,
  }) : _glifos = glifos,
       _emblemaBlanco = emblemaBlanco,
       _emblemaMarca = emblemaMarca;

  static const String _fuenteRegular =
      'assets/fonts/PlusJakartaSans-Regular.ttf';
  static const String _fuenteSemiBold =
      'assets/fonts/PlusJakartaSans-SemiBold.ttf';
  static const String _fuenteBold = 'assets/fonts/PlusJakartaSans-Bold.ttf';
  static const String _fuenteCinzel = 'assets/fonts/Cinzel-Bold.ttf';
  static const String _emblemaAsset = 'assets/brand/atena_mark.png';

  /// Color del emblema sobre fondos claros (índigo de la marca).
  static const PdfColor _indigo = PdfColor.fromInt(0xFF4F46E5);

  final pw.Font regular;
  final pw.Font semiBold;
  final pw.Font bold;

  /// Tipografía del logotipo "ATENA".
  final pw.Font cinzel;

  final Set<int> _glifos;
  final _Raster? _emblemaBlanco;
  final _Raster? _emblemaMarca;

  static Future<PdfRecursos>? _carga;

  /// Recursos compartidos. Si la carga falla, el próximo pedido reintenta.
  static Future<PdfRecursos> cargar() {
    final enCurso = _carga;
    if (enCurso != null) return enCurso;
    final nueva = _cargar();
    _carga = nueva;
    nueva.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_carga, nueva)) _carga = null;
      },
    );
    return nueva;
  }

  static Future<PdfRecursos> _cargar() async {
    // Una por una: el bundle puede devolver futuros sincrónicos, que
    // Future.wait no admite.
    final regular = await rootBundle.load(_fuenteRegular);
    final semiBold = await rootBundle.load(_fuenteSemiBold);
    final bold = await rootBundle.load(_fuenteBold);
    final cinzel = await rootBundle.load(_fuenteCinzel);
    // El blanco se usa grande (marca de agua de la banda); el índigo solo en
    // el pie, así que alcanza con una versión chica y liviana.
    final emblemaGrande = await _cargarEmblema(256);
    final emblemaChico = await _cargarEmblema(64);
    return PdfRecursos._(
      regular: pw.Font.ttf(regular),
      semiBold: pw.Font.ttf(semiBold),
      bold: pw.Font.ttf(bold),
      cinzel: pw.Font.ttf(cinzel),
      glifos: TtfParser(regular).charToGlyphIndexMap.keys.toSet(),
      emblemaBlanco: emblemaGrande?.coloreado(PdfColors.white),
      emblemaMarca: emblemaChico?.coloreado(_indigo),
    );
  }

  /// El emblema es decorativo: si no se puede cargar, los documentos usan
  /// solo el logotipo de texto.
  static Future<_Raster?> _cargarEmblema(int lado) async {
    try {
      final datos = await rootBundle.load(_emblemaAsset);
      return await _decodificar(
        datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
        lado,
      );
    } catch (_) {
      return null;
    }
  }

  /// Emblema blanco (para la banda de color) o índigo (para fondos claros).
  pw.ImageProvider? emblema({required bool sobreColor}) =>
      (sobreColor ? _emblemaBlanco : _emblemaMarca)?.imagen();

  /// Imagen lista para el PDF, o null si los bytes no son una imagen válida.
  /// Las JPEG se insertan tal cual (más livianas); el resto se decodifica y se
  /// reduce a [ladoMaximo] píxeles.
  static Future<pw.ImageProvider?> imagen(
    Uint8List? bytes, {
    int ladoMaximo = 256,
  }) async {
    if (bytes == null || bytes.length < 4) return null;
    final esJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    if (esJpeg) {
      try {
        return pw.MemoryImage(bytes);
      } catch (_) {
        // Encabezado JPEG inusual: se intenta decodificar a continuación.
      }
    }
    return (await _decodificar(bytes, ladoMaximo))?.imagen();
  }

  static Future<_Raster?> _decodificar(Uint8List bytes, int ladoMaximo) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (ancho, alto) {
          final mayor = math.max(ancho, alto);
          if (mayor <= ladoMaximo) return const ui.TargetImageSize();
          final escala = ladoMaximo / mayor;
          return ui.TargetImageSize(
            width: math.max(1, (ancho * escala).round()),
            height: math.max(1, (alto * escala).round()),
          );
        },
      );
      try {
        final cuadro = await codec.getNextFrame();
        final img = cuadro.image;
        try {
          final datos = await img.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          if (datos == null) return null;
          return _Raster(
            datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes),
            img.width,
            img.height,
          );
        } finally {
          img.dispose();
        }
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Textos
  // ---------------------------------------------------------------------------

  /// Adapta un texto a la tipografía: normaliza espacios, reemplaza letras sin
  /// glifo por su letra base y descarta lo que no se puede dibujar (emojis).
  /// Con [multilinea] conserva los saltos de línea (como mucho uno en blanco).
  String limpiar(String texto, {bool multilinea = false}) {
    if (texto.isEmpty) return texto;
    final sb = StringBuffer();
    for (final rune in texto.replaceAll('\r\n', '\n').runes) {
      if (rune == 0x0A || rune == 0x0D) {
        sb.write(multilinea ? '\n' : ' ');
      } else if (rune == 0x09 || _esEspacio(rune)) {
        sb.write(' ');
      } else if (_esInvisible(rune)) {
        // Caracteres de control y marcas de ancho cero: no se dibujan.
        continue;
      } else if (_glifos.contains(rune)) {
        sb.writeCharCode(rune);
      } else {
        final equivalente = _equivalencias[rune];
        if (equivalente != null) sb.write(equivalente);
      }
    }
    var s = sb.toString().replaceAll(_espaciosRepetidos, ' ');
    if (multilinea) {
      s = s
          .replaceAll(_espaciosEnSalto, '\n')
          .replaceAll(_saltosRepetidos, '\n\n');
    }
    return s.trim();
  }

  static final RegExp _espaciosRepetidos = RegExp(' {2,}');
  static final RegExp _espaciosEnSalto = RegExp(' *\n *');
  static final RegExp _saltosRepetidos = RegExp('\n{3,}');

  static bool _esEspacio(int rune) =>
      rune == 0xA0 ||
      rune == 0x1680 ||
      (rune >= 0x2000 && rune <= 0x200A) ||
      rune == 0x202F ||
      rune == 0x205F ||
      rune == 0x3000;

  static bool _esInvisible(int rune) =>
      rune < 0x20 ||
      (rune >= 0x7F && rune <= 0x9F) ||
      (rune >= 0x200B && rune <= 0x200F) ||
      rune == 0xFEFF;

  /// Letras de otros alfabetos latinos que la tipografía no trae.
  static final Map<int, String> _equivalencias = {
    for (final e in const {
      'ĀĂĄ': 'A',
      'āăą': 'a',
      'ĆĈĊČ': 'C',
      'ćĉċč': 'c',
      'ĎĐ': 'D',
      'ďđ': 'd',
      'ĒĔĖĘĚ': 'E',
      'ēĕėęě': 'e',
      'ĜĞĠĢ': 'G',
      'ĝğġģ': 'g',
      'ĤĦ': 'H',
      'ĥħ': 'h',
      'ĨĪĬĮİ': 'I',
      'ĩīĭįı': 'i',
      'Ĵ': 'J',
      'ĵ': 'j',
      'Ķ': 'K',
      'ķ': 'k',
      'ĹĻĽĿŁ': 'L',
      'ĺļľŀł': 'l',
      'ŃŅŇ': 'N',
      'ńņň': 'n',
      'ŌŎŐ': 'O',
      'ōŏő': 'o',
      'Œ': 'OE',
      'œ': 'oe',
      'ŔŖŘ': 'R',
      'ŕŗř': 'r',
      'ŚŜŞŠȘ': 'S',
      'śŝşšș': 's',
      'ŢŤŦȚ': 'T',
      'ţťŧț': 't',
      'ŨŪŬŮŰŲ': 'U',
      'ũūŭůűų': 'u',
      'Ŵ': 'W',
      'ŵ': 'w',
      'ŶŸ': 'Y',
      'ŷ': 'y',
      'ŹŻŽ': 'Z',
      'źżž': 'z',
      '‐‑‒―': '-',
      '′': "'",
      '″': '"',
    }.entries)
      for (final rune in e.key.runes) rune: e.value,
  };
}
