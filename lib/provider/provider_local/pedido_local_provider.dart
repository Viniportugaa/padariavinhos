import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';

/// ===============================
/// CONTEXTO DO PROVIDER
/// ===============================
enum PedidoContexto {
  mesa,
  pedidoExistente,
}

class PedidoLocalProvider extends ChangeNotifier {
  String? _mesaAtual;
  final List<ItemCarrinho> _itens = [];
  bool _carregado = false;

  PedidoContexto _contexto = PedidoContexto.mesa;
  String? _pedidoEditandoId;

  // =========================
  // GETTERS
  // =========================
  String? get mesaAtual => _mesaAtual;
  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  bool get carregado => _carregado;
  PedidoContexto get contexto => _contexto;
  bool get editandoPedido => _contexto == PedidoContexto.pedidoExistente;

  double get total => _itens.fold(0, (sum, i) => sum + i.subtotal);

  // ===========================================================================
  // 🔥 INICIALIZAÇÃO (MODO MESA)
  // ===========================================================================
  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    _mesaAtual = prefs.getString('mesaAtual');

    _contexto = PedidoContexto.mesa;
    _pedidoEditandoId = null;

    if (_mesaAtual != null) {
      await _criarOuAbrirMesa();
      await _carregarItensMesa();
    }

    _carregado = true;
    notifyListeners();
  }

  // ===========================================================================
  // 🔥 DEFINIR MESA
  // ===========================================================================
  Future<void> definirMesa(String mesa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mesaAtual', mesa);

    _mesaAtual = mesa;
    _contexto = PedidoContexto.mesa;
    _pedidoEditandoId = null;

    await _criarOuAbrirMesa();
    await _carregarItensMesa();

    notifyListeners();
  }

  // ===========================================================================
  // 🔥 FIRESTORE — MESA
  // ===========================================================================
  Future<void> _criarOuAbrirMesa() async {
    final ref =
    FirebaseFirestore.instance.collection('mesas').doc(_mesaAtual);

    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'mesa': _mesaAtual,
        'status': 'aberta',
        'total': 0,
        'abertaEm': Timestamp.now(),
      });
    }
  }

  Future<void> _carregarItensMesa() async {
    _itens.clear();

    final snap = await FirebaseFirestore.instance
        .collection('mesas')
        .doc(_mesaAtual)
        .collection('itens')
        .get();

    _itens.addAll(
      snap.docs.map((d) => ItemCarrinho.fromMap(d.data())),
    );
  }

  // ===========================================================================
  // 🔥 ADICIONAR ITEM
  // ===========================================================================
  Future<void> adicionarItem(ItemCarrinho item) async {
    _itens.add(item);
    notifyListeners();

    final firestore = FirebaseFirestore.instance;

    if (_contexto == PedidoContexto.pedidoExistente &&
        _pedidoEditandoId != null) {
      await firestore
          .collection('pedidos_local')
          .doc(_pedidoEditandoId)
          .collection('itens')
          .doc(item.idUnico)
          .set(item.toMap());

      await firestore
          .collection('pedidos_local')
          .doc(_pedidoEditandoId)
          .update({'total': total});
    } else if (_mesaAtual != null) {
      await firestore
          .collection('mesas')
          .doc(_mesaAtual)
          .collection('itens')
          .doc(item.idUnico)
          .set(item.toMap());

      await _atualizarTotalMesa();
    }
  }

  // ===========================================================================
  // 🔥 ATUALIZAR ITEM
  // ===========================================================================
  Future<void> atualizarItem(ItemCarrinho item) async {
    final index = _itens.indexWhere((i) => i.idUnico == item.idUnico);

    if (index >= 0) {
      _itens[index] = item;
    } else {
      _itens.add(item);
    }

    notifyListeners();

    final firestore = FirebaseFirestore.instance;

    if (_contexto == PedidoContexto.pedidoExistente &&
        _pedidoEditandoId != null) {
      await firestore
          .collection('pedidos_local')
          .doc(_pedidoEditandoId)
          .collection('itens')
          .doc(item.idUnico)
          .set(item.toMap());

      await firestore
          .collection('pedidos_local')
          .doc(_pedidoEditandoId)
          .update({'total': total});
    } else if (_mesaAtual != null) {
      await firestore
          .collection('mesas')
          .doc(_mesaAtual)
          .collection('itens')
          .doc(item.idUnico)
          .set(item.toMap());

      await _atualizarTotalMesa();
    }
  }

  // ===========================================================================
  // 🔥 REMOVER ITEM (COESO)
  // ===========================================================================
  Future<void> removerItem(ItemCarrinho item) async {
    _itens.removeWhere((i) => i.idUnico == item.idUnico);
    notifyListeners();

    final firestore = FirebaseFirestore.instance;

    if (_contexto == PedidoContexto.pedidoExistente &&
        _pedidoEditandoId != null) {
      await firestore
          .collection('pedidos_local')
          .doc(_pedidoEditandoId)
          .collection('itens')
          .doc(item.idUnico)
          .delete();

      await firestore
          .collection('pedidos_local')
          .doc(_pedidoEditandoId)
          .update({'total': total});
    } else if (_mesaAtual != null) {
      await firestore
          .collection('mesas')
          .doc(_mesaAtual)
          .collection('itens')
          .doc(item.idUnico)
          .delete();

      await _atualizarTotalMesa();
    }
  }

  // ===========================================================================
  // 🔥 TOTAL MESA
  // ===========================================================================
  Future<void> _atualizarTotalMesa() async {
    if (_mesaAtual == null) return;

    await FirebaseFirestore.instance
        .collection('mesas')
        .doc(_mesaAtual)
        .update({'total': total});
  }

  // ===========================================================================
  // 🔥 FINALIZAR PEDIDO (MESA → PEDIDO)
  // ===========================================================================
  Future<void> finalizarPedido({
    required String formaPagamento,
    double gorjeta = 0,
  }) async {
    if (_mesaAtual == null || _itens.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final pedidoRef = firestore.collection('pedidos_local').doc();

    await pedidoRef.set({
      'id': pedidoRef.id,
      'mesa': _mesaAtual,
      'status': 'pendente',
      'data': Timestamp.now(),
      'formaPagamento': formaPagamento,
      'gorjeta': gorjeta,
      'total': total,
    });

    for (final item in _itens) {
      await pedidoRef
          .collection('itens')
          .doc(item.idUnico)
          .set(item.toMap());
    }

    final mesaRef = firestore.collection('mesas').doc(_mesaAtual);
    final itensSnap = await mesaRef.collection('itens').get();

    for (final d in itensSnap.docs) {
      await d.reference.delete();
    }

    _itens.clear();
    notifyListeners();
  }

  // ===========================================================================
  // 🔥 CARREGAR PEDIDO EXISTENTE (EDIÇÃO)
  // ===========================================================================
  Future<void> carregarPedidoExistente(String pedidoId) async {
    final firestore = FirebaseFirestore.instance;

    _contexto = PedidoContexto.pedidoExistente;
    _pedidoEditandoId = pedidoId;

    _itens.clear();
    _mesaAtual = null;
    _carregado = false;
    notifyListeners();

    final itensSnap = await firestore
        .collection('pedidos_local')
        .doc(pedidoId)
        .collection('itens')
        .get();

    _itens.addAll(
      itensSnap.docs.map((d) => ItemCarrinho.fromMap(d.data())),
    );

    _carregado = true;
    notifyListeners();
  }

  // ===========================================================================
  // 🔥 CATÁLOGO
  // ===========================================================================
  Future<List<Produto>> carregarProdutosComAcompanhamentos() async {
    final firestore = FirebaseFirestore.instance;

    final produtosSnap = await firestore
        .collection('produtos')
        .where('disponivelLocal', isEqualTo: true)
        .get();

    final acompSnap = await firestore.collection('acompanhamentos').get();
    final todos = acompSnap.docs
        .map((d) => Acompanhamento.fromMap(d.data(), d.id))
        .toList();

    return produtosSnap.docs.map((d) {
      final data = d.data();
      final ids = List<String>.from(data['acompanhamentosIds'] ?? []);
      final disponiveis = todos.where((a) => ids.contains(a.id)).toList();

      return Produto.fromMap(
        data,
        d.id,
        acompanhamentosDisponiveis: disponiveis,
      );
    }).toList();
  }

  // ===========================================================================
  // 🔥 FORÇA REFRESH UI
  // ===========================================================================
  void notificarAtualizacao() {
    notifyListeners();
  }
}
