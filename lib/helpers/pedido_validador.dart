import 'distancia_helper.dart';
import 'package:flutter/material.dart';

class PedidoValidador {
  static const double valorMinimo = 20.0;
  static const double alcanceKm = 1.5;

  /// Coordenadas da loja (CEP 01435-000)
  static const double lojaLat = -23.57904;
  static const double lojaLng = -46.66832;

  static bool validarValor(double total) {
    debugPrint("💰 Valor do pedido: R\$ ${total.toStringAsFixed(2)} "
        "| Mínimo: R\$ ${valorMinimo.toStringAsFixed(2)}");
    return total >= valorMinimo;
  }

  static bool validarAlcance(double userLat, double userLng) {
    debugPrint("🏪 Loja em: ($lojaLat, $lojaLng)");
    debugPrint("👤 Cliente em: ($userLat, $userLng)");

    final distancia =
    DistanciaHelper.calcularDistancia(lojaLat, lojaLng, userLat, userLng);

    debugPrint("📏 Distância calculada até a loja: ${distancia.toStringAsFixed(3)} km");
    debugPrint("📌 Alcance permitido: $alcanceKm km");

    final dentro = distancia <= alcanceKm;
    debugPrint(dentro
        ? "✅ Endereço dentro da área de entrega."
        : "❌ Endereço fora da área de entrega.");

    return dentro;
  }
}
