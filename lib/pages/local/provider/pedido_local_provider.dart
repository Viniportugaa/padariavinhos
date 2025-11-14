import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoLocalProvider with ChangeNotifier {
  final List<ItemCarrinho> _itens = [];
  String? _numeroMesa;
  int? _posicaoMesa;
  String? _pedidoAtivoId;


  PedidoLocalProvider() {
    _carregarMesaPersistida();
  }

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  String? get numeroMesa => _numeroMesa;
  int? get posicaoMesa => _posicaoMesa;
  String? get pedidoAtivoId => _pedidoAtivoId;

  // 🔹 Define mesa e salva localmente
  Future<void> definirMesa(String numero, int posicao) async {
    _numeroMesa = numero;
    _posicaoMesa = posicao;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('numeroMesa', numero);
    await prefs.setInt('posicaoMesa', posicao);
  }

  // 🔹 Verifica se existe um pedido aberto para a mesa ou cria um novo
  Future<void> abrirOuRecuperarPedido() async {
    final firestore = FirebaseFirestore.instance;
    final pedidos = firestore.collection('pedidos_local');

    final query = await pedidos
        .where('mesa', isEqualTo: _numeroMesa)
        .where('status', whereIn: ['aberto', 'pendente'])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      _pedidoAtivoId = query.docs.first.id;
    } else {
      final doc = await pedidos.add({
        'mesa': _numeroMesa,
        'posicao': _posicaoMesa,
        'status': 'pendente', // 🔸 já pendente para aparecer no painel
        'data': Timestamp.now(), // 🔸 campo usado pelo painel
        'total': 0.0,
      });
      _pedidoAtivoId = doc.id;
    }

    notifyListeners();
  }

  // 🔹 Adiciona item localmente e no Firestore
  Future<void> adicionarItem(ItemCarrinho item) async {
    if (_pedidoAtivoId == null) await abrirOuRecuperarPedido();

    _itens.add(item);
    notifyListeners();

    final firestore = FirebaseFirestore.instance;
    final pedidoRef =
    firestore.collection('pedidos_local').doc(_pedidoAtivoId);

    // 🔸 salva o item no subdocumento
    await pedidoRef.collection('itens').add(item.toMap());

    // 🔸 garante que o pedido tenha status "pendente" para o painel enxergar
    final doc = await pedidoRef.get();
    if ((doc['status'] ?? '') == 'aberto') {
      await pedidoRef.update({'status': 'pendente'});
    }

    await _atualizarTotal();
  }

  // 🔹 Atualiza o total do pedido com segurança
  Future<void> _atualizarTotal() async {
    if (_pedidoAtivoId == null) return;

    final firestore = FirebaseFirestore.instance;
    final itensSnapshot = await firestore
        .collection('pedidos_local')
        .doc(_pedidoAtivoId)
        .collection('itens')
        .get();

    final total = itensSnapshot.docs.fold<double>(
      0,
          (sum, doc) {
        final data = doc.data();
        final dynamic raw = data['subtotal'];
        final valor = (raw is num) ? raw.toDouble() : 0.0;
        return sum + valor;
      },
    );

    await firestore
        .collection('pedidos_local')
        .doc(_pedidoAtivoId)
        .update({'total': total});
  }

  // 🔹 Finaliza pedido (encerra conta)
  Future<void> finalizarPedido({
    required String formaPagamento,
    double gorjeta = 0,
  }) async {
    if (_pedidoAtivoId == null) return;

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('pedidos_local').doc(_pedidoAtivoId).update({
      'status': 'fechado',
      'dataFechamento': Timestamp.now(),
      'formaPagamento': formaPagamento,
      'gorjeta': gorjeta,
    });

    _itens.clear();
    _pedidoAtivoId = null;
    notifyListeners();
  }

  // 🔹 Total local
  double get total => _itens.fold(0.0, (sum, i) => sum + i.subtotal);

  // 🔹 Recupera mesa persistida
  Future<void> _carregarMesaPersistida() async {
    final prefs = await SharedPreferences.getInstance();
    _numeroMesa = prefs.getString('numeroMesa');
    _posicaoMesa = prefs.getInt('posicaoMesa');
    notifyListeners();
  }

  // 🔹 Funções utilitárias
  void removerItem(ItemCarrinho item) {
    _itens.removeWhere((i) => i.idUnico == item.idUnico);
    notifyListeners();
  }

  void limparItens() {
    _itens.clear();
    notifyListeners();
  }

  Future<void> limparTudo() async {
    _itens.clear();
    _numeroMesa = null;
    _posicaoMesa = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('numeroMesa');
    await prefs.remove('posicaoMesa');
    notifyListeners();
  }

  void aumentarQuantidade(ItemCarrinho item) {
    final index = _itens.indexWhere((i) => i.idUnico == item.idUnico);
    if (index != -1) {
      _itens[index].quantidade++;
      notifyListeners();
    }
  }

  void diminuirQuantidade(ItemCarrinho item) {
    final index = _itens.indexWhere((i) => i.idUnico == item.idUnico);
    if (index != -1) {
      if (_itens[index].quantidade > 1) {
        _itens[index].quantidade--;
      } else {
        _itens.removeAt(index);
      }
      notifyListeners();
    }
  }
}
