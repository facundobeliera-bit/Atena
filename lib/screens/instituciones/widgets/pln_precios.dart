// lib/screens/instituciones/widgets/pln_precios.dart
//
// Reglas de precio del plan de la institución:
// - USD 10 por nivel curricular y USD 15 por módulo extracurricular, por mes.
// - 5 % de descuento a partir de 3 ítems.
// - Código promocional con 100 % de descuento y cupo de usos, contado en el
//   dispositivo (todavía no hay integración de pagos).

import '../../../core/atena_core.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/extracurriculares/bloque_extracurricular.dart';

/// Valores del plan. Los importes van en centavos de dólar para no arrastrar
/// errores de redondeo.
class PlnPrecios {
  const PlnPrecios._();

  static const int porNivel = 1000;
  static const int porModulo = 1500;
  static const int itemsParaDescuento = 3;
  static const int porcentajeDescuento = 5;
  static const int diasPrueba = 30;
}

/// Costo mensual de una selección de niveles y módulos.
class PlnCalculo {
  final int niveles;
  final int modulos;
  final bool promo;

  const PlnCalculo({
    required this.niveles,
    required this.modulos,
    this.promo = false,
  });

  int get items => niveles + modulos;
  bool get vacio => items == 0;

  int get importeNiveles => niveles * PlnPrecios.porNivel;
  int get importeModulos => modulos * PlnPrecios.porModulo;
  int get subtotal => importeNiveles + importeModulos;

  bool get conDescuento => items >= PlnPrecios.itemsParaDescuento;
  int get descuento =>
      conDescuento ? subtotal * PlnPrecios.porcentajeDescuento ~/ 100 : 0;

  int get descuentoPromo =>
      promo ? (subtotal - descuento) * PlnPromo.porcentaje ~/ 100 : 0;

  int get total => subtotal - descuento - descuentoPromo;

  /// El plan elegido no tiene costo (solo pasa con el código promocional).
  bool get gratis => !vacio && total == 0;

  /// Ítems que faltan para el descuento por cantidad (0 si ya aplica).
  int get faltanParaDescuento =>
      conDescuento ? 0 : PlnPrecios.itemsParaDescuento - items;
}

/// "USD 10" o "USD 33,25", con el separador decimal del idioma activo.
String plnUsd(AppLocalizations t, int centavos) => centavos % 100 == 0
    ? t.plnUsd(centavos ~/ 100)
    : t.plnUsdDecimal(centavos / 100);

const String _marcaPromo = '-promo';

/// Clave legible del plan que se guarda en `Institucion.tipoPlan`:
/// "modular-2n-1m" (2 niveles, 1 módulo) o "modular-0n-3m-promo".
String plnClavePlan(PlnCalculo c) =>
    'modular-${c.niveles}n-${c.modulos}m${c.promo ? _marcaPromo : ''}';

/// true si el plan guardado ya tiene el código promocional aplicado.
bool plnPlanConPromo(String tipoPlan) =>
    tipoPlan.trim().toLowerCase().endsWith(_marcaPromo);

enum PlnPromoResultado { valido, invalido, agotado }

/// Código promocional de lanzamiento. Cada institución lo canjea una sola vez
/// y los canjes se cuentan en el dispositivo hasta completar el cupo.
class PlnPromo {
  const PlnPromo._();

  static const int porcentaje = 100;
  static const int cupo = 100;

  static const String _codigo = 'ATHENA2026';
  static const String _clave = 'plan.promo.lanzamiento';
  static const String _campo = 'instituciones';

  static Future<List<String>> _canjes() async {
    final doc = await AtenaStore.instance.readSingle(_clave);
    final lista = doc?[_campo];
    return lista is List ? lista.whereType<String>().toList() : <String>[];
  }

  static bool _coincide(String ingresado) =>
      ingresado.replaceAll(RegExp(r'\s+'), '').toUpperCase() == _codigo;

  /// Verifica un código ingresado por el usuario.
  static Future<PlnPromoResultado> verificar(
    String ingresado, {
    String? institucionId,
  }) async {
    if (!_coincide(ingresado)) return PlnPromoResultado.invalido;
    return await hayCupo(institucionId: institucionId)
        ? PlnPromoResultado.valido
        : PlnPromoResultado.agotado;
  }

  /// La institución que ya lo canjeó puede volver a aplicarlo sin gastar
  /// otro uso.
  static Future<bool> hayCupo({String? institucionId}) async {
    final canjes = await _canjes();
    if (institucionId != null && canjes.contains(institucionId)) return true;
    return canjes.length < cupo;
  }

  /// Registra el uso del código por parte de la institución.
  static Future<void> canjear(String institucionId) async {
    final canjes = await _canjes();
    if (canjes.contains(institucionId)) return;
    await AtenaStore.instance.writeSingle(_clave, {
      _campo: [...canjes, institucionId],
    });
  }
}

/// Descripción corta de lo que cubre cada módulo extracurricular.
String plnDescripcionBloque(AppLocalizations t, BloqueExtracurricular b) =>
    switch (b) {
      BloqueExtracurricular.deporteYMovimiento => t.plnBloqueDeporte,
      BloqueExtracurricular.arteYExpresion => t.plnBloqueArte,
      BloqueExtracurricular.idiomasYComunicacion => t.plnBloqueIdiomas,
      BloqueExtracurricular.cienciaTecnologiaYRobotica => t.plnBloqueCiencia,
      BloqueExtracurricular.apoyoAcademico => t.plnBloqueApoyo,
      BloqueExtracurricular.desarrolloPersonalYBienestar =>
        t.plnBloqueBienestar,
      BloqueExtracurricular.otros => t.plnBloqueOtros,
    };
