import 'package:flutter/material.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class PedidoStatus {
  static const pendente = 'pendente';
  static const emPreparo = 'em preparo';
  static const finalizado = 'finalizado';
  static const cancelado = 'cancelado';
}

class PedidoProvider extends ChangeNotifier {
  final PedidoService _pedidoService = PedidoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------- Cálculos -----------------
  double subtotal(Pedido pedido) => pedido.subtotal;
  double totalComFrete(Pedido pedido) => pedido.totalFinal;

  // ----------------- Status e persistência -----------------
  Future<void> finalizar(Pedido pedido) async {
    pedido.status = PedidoStatus.finalizado;
    notifyListeners();

    await _firestore.collection('pedidos').doc(pedido.id).update({
      'status': PedidoStatus.finalizado,
      'totalFinal': pedido.totalFinal,
    });

    await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);
  }

  Future<void> cancelar(Pedido pedido) async {
    pedido.status = PedidoStatus.cancelado;
    notifyListeners();

    await _firestore.collection('pedidos').doc(pedido.id).update({
      'status': PedidoStatus.cancelado,
      'dataCancelamento': DateTime.now(),
      'notificacao':
      'Seu pedido foi cancelado. Por favor, entre em contato: 1199999900',
      'totalFinal': pedido.totalFinal,
    });

    await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);
  }

  Future<void> colocarEmPreparo(Pedido pedido) async {
    if (pedido.status == PedidoStatus.pendente) {
      pedido.status = PedidoStatus.emPreparo;
      notifyListeners();

      await _firestore.collection('pedidos').doc(pedido.id).update({
        'status': PedidoStatus.emPreparo,
        'totalFinal': pedido.totalFinal,
      });

      await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);
    }
  }
  Future<void> imprimirPedido(
      Pedido pedido, User usuario, BuildContext context) async {
    await _pedidoService.imprimirPedido(pedido, usuario, context);
    notifyListeners();
  }

  Future<void> cancelarComMotivo(Pedido pedido, String motivo) async {
    try {
      // 🔹 Atualiza o status localmente
      pedido.status = 'cancelado'; // mantém coerência com o tipo String do modelo
      notifyListeners();

      // 🔹 Chama o serviço que faz o update no Firestore
      await _pedidoService.cancelarPedido(pedido.id, motivo);

      // 🔹 (Opcional) Atualiza outros campos adicionais no documento
      await _firestore.collection('pedidos').doc(pedido.id).update({
        'totalFinal': pedido.totalFinal,
        'notificacao': 'Seu pedido foi cancelado. Motivo: $motivo',
      });

      // 🔹 Mantém a coerência de valor (caso tenha sido ajustado)
      await _pedidoService.ajustarValorPedido(pedido.id, pedido.totalFinal);

      debugPrint('✅ Pedido ${pedido.id} cancelado com motivo: $motivo');
    } catch (e) {
      debugPrint('❌ Erro ao cancelar pedido com motivo: $e');
      rethrow;
    }
  }


}