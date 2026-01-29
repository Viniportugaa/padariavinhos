import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class PedidosBalcaoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _subAtivos;
  StreamSubscription? _subHistorico;

  bool _loading = true;

  final Map<String, PedidoLocal> _ultimoPedidoPorMesa = {};
  final List<PedidoLocal> _historico = [];
  final Map<String, List<ItemCarrinho>> _itensCache = {};

  bool get loading => _loading;

  /// Pedidos ativos (1 por mesa)
  List<PedidoLocal> get pedidos =>
      _ultimoPedidoPorMesa.values.toList()
        ..sort((a, b) => b.data.compareTo(a.data));

  /// Histórico completo
  List<PedidoLocal> get pedidosHistorico =>
      List.unmodifiable(_historico);

  // ======================================================
  // 🔥 ESCUTA PEDIDOS ATIVOS (Painel do balcão)
  // ======================================================
  void startListening() {
    _subAtivos?.cancel();
    _loading = true;

    _subAtivos = _firestore
        .collection('pedidos_local')
        .where('status', isNotEqualTo: 'fechado')
        .orderBy('status')
        .orderBy('data', descending: true)
        .snapshots()
        .listen((snapshot) {
      _ultimoPedidoPorMesa.clear();

      for (final doc in snapshot.docs) {
        final pedido = PedidoLocal.fromFirestore(doc);

        // mantém apenas o último pedido por mesa
        _ultimoPedidoPorMesa.putIfAbsent(pedido.mesa, () => pedido);
      }

      _loading = false;
      notifyListeners();
    });
  }

  void startListeningPedidosHoje() {
    _subAtivos?.cancel();
    _loading = true;

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
        .orderBy('data', descending: true)
        .snapshots()
        .listen((snapshot) {
      _ultimoPedidoPorMesa.clear();

      for (final doc in snapshot.docs) {
        final pedido = PedidoLocal.fromFirestore(doc);

        // 🔹 mostra TODOS (não agrupa mais por mesa)
        _ultimoPedidoPorMesa[pedido.id] = pedido;
      }

      _loading = false;
      notifyListeners();
    });
  }

  // ======================================================
  // 🔥 ESCUTA HISTÓRICO
  // ======================================================
  void startListeningHistorico() {
    _subHistorico?.cancel();
    _loading = true;

    _subHistorico = _firestore
        .collection('pedidos_local')
        .where('status', isEqualTo: 'fechado')
        .orderBy('data', descending: true)
        .snapshots()
        .listen((snapshot) {
      _historico
        ..clear()
        ..addAll(
          snapshot.docs.map(
                (d) => PedidoLocal.fromFirestore(d),
          ),
        );

      _loading = false;
      notifyListeners();
    });
  }

  // ======================================================
  // 🔥 ITENS (lazy + cache)
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
  // 🔥 ALTERAR STATUS
  // ======================================================
  Future<void> alterarStatus(String pedidoId, String status) async {
    await _firestore
        .collection('pedidos_local')
        .doc(pedidoId)
        .update({'status': status});
  }

  // ======================================================
  // 🔥 LIMPAR
  // ======================================================
  @override
  void dispose() {
    _subAtivos?.cancel();
    _subHistorico?.cancel();
    super.dispose();
  }
}
