import 'package:flutter/foundation.dart';
import 'package:padariavinhos/services/pedido_listener_service.dart';

class PedidoListenerNotifier extends ChangeNotifier {
  final PedidoListenerService _service;
  final String userId;

  bool temAtualizacao = false;
  final Map<String, String> _statusAnterior = {};

  PedidoListenerNotifier(this._service, this.userId) {
    _iniciarEscuta();
  }

  void _iniciarEscuta() {
    _service.listenPedidos(userId).listen((listaPedidos) {
      bool houveMudanca = false;

      for (final pedido in listaPedidos) {
        final id = pedido['id'] as String;
        final novoStatus = pedido['status'] as String? ?? '';
        final antigo = _statusAnterior[id] ?? '';

        if (antigo.isNotEmpty && novoStatus != antigo) {
          houveMudanca = true;
        }

        _statusAnterior[id] = novoStatus;
      }

      if (houveMudanca) {
        temAtualizacao = true;
        notifyListeners();
      }
    });
  }

  void limparAtualizacao() {
    temAtualizacao = false;
    notifyListeners();
  }
}
