import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class PedidosBalcaoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _subAtivos;
  StreamSubscription<QuerySnapshot>? _subHistorico;

  bool _loading = false;
  bool get loading => _loading;

  final Map<String, PedidoLocal> _pedidosPorMesa = {};
  final List<PedidoLocal> _historico = [];
  final Map<String, List<ItemCarrinho>> _itensCache = {};

  List<PedidoLocal> get pedidosAtivos =>
      _pedidosPorMesa.values.toList()
        ..sort((a, b) => b.data.compareTo(a.data));

  List<PedidoLocal> get pedidosHistorico =>
      List.unmodifiable(_historico);

  // ======================================================
  // 🔥 ATIVOS (real-time, 1 por mesa)
  // ======================================================
  void listenPedidosAtivos() {
    _subAtivos?.cancel();
    _loading = true;
    notifyListeners();

    _subAtivos = _firestore
        .collection('pedidos_local')
        .where('status', isNotEqualTo: 'fechado')
        .snapshots()
        .listen((snapshot) {
      _pedidosPorMesa.clear();

      for (final doc in snapshot.docs) {
        final pedido = PedidoLocal.fromFirestore(doc);

        final atual = _pedidosPorMesa[pedido.mesa];
        if (atual == null || pedido.data.isAfter(atual.data)) {
          _pedidosPorMesa[pedido.mesa] = pedido;
        }
      }

      _loading = false;
      notifyListeners();
    });
  }

  // ======================================================
  // 🔥 PEDIDOS DE HOJE (sem agrupar)
  // ======================================================
  void listenPedidosHoje() {
    _subAtivos?.cancel();
    _loading = true;
    notifyListeners();

    final agora = DateTime.now();
    final inicioDia = DateTime(agora.year, agora.month, agora.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    _subAtivos = _firestore
        .collection('pedidos_local')
        .where(
      'data',
      isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia),
    )
        .where(
      'data',
      isLessThan: Timestamp.fromDate(fimDia),
    )
        .snapshots()
        .listen((snapshot) {
      _pedidosPorMesa.clear();

      for (final doc in snapshot.docs) {
        final pedido = PedidoLocal.fromFirestore(doc);
        _pedidosPorMesa[pedido.id] = pedido;
      }

      _loading = false;
      notifyListeners();
    });
  }

  // ======================================================
  // 🔥 HISTÓRICO (fechados)
  // ======================================================
  void listenHistorico() {
    _subHistorico?.cancel();
    _loading = true;
    notifyListeners();

    _subHistorico = _firestore
        .collection('pedidos_local')
        .where('status', isEqualTo: 'fechado')
        .snapshots()
        .listen((snapshot) {
      _historico
        ..clear()
        ..addAll(snapshot.docs.map(PedidoLocal.fromFirestore));

      _historico.sort((a, b) => b.data.compareTo(a.data));

      _loading = false;
      notifyListeners();
    });
  }

  Stream<List<ItemCarrinho>> streamItensPedido(String pedidoId) {
    return _firestore
        .collection('pedidos_local')
        .doc(pedidoId)
        .collection('itens')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => ItemCarrinho.fromMap(d.data())).toList());
  }

  // ======================================================
  // 🔥 ITENS (cache lazy)
  // ======================================================
  Future<List<ItemCarrinho>> carregarItens(String pedidoId) async {
    if (_itensCache.containsKey(pedidoId)) {
      return _itensCache[pedidoId]!;
    }

    final itens = await PedidoLocal.carregarItens(pedidoId);
    _itensCache[pedidoId] = itens;
    return itens;
  }

  // ======================================================
  // 🔥 STATUS
  // ======================================================
  Future<void> alterarStatus(String pedidoId, String status) {
    return _firestore
        .collection('pedidos_local')
        .doc(pedidoId)
        .update({'status': status});
  }

  // ======================================================
  // 🔥 CLEANUP
  // ======================================================
  @override
  void dispose() {
    _subAtivos?.cancel();
    _subHistorico?.cancel();
    super.dispose();
  }
}
