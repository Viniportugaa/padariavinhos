import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class PedidoLocalProvider with ChangeNotifier {
  final List<ItemCarrinho> _itens = [];
  String? _numeroMesa;
  int? _posicaoMesa;

  PedidoLocalProvider() {
    _carregarMesaPersistida();
  }

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  String? get numeroMesa => _numeroMesa;
  int? get posicaoMesa => _posicaoMesa;

  Future<void> definirMesa(String numero, int posicao) async {
    _numeroMesa = numero;
    _posicaoMesa = posicao;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('numeroMesa', numero);
    await prefs.setInt('posicaoMesa', posicao);
  }

  Future<void> _carregarMesaPersistida() async {
    final prefs = await SharedPreferences.getInstance();
    _numeroMesa = prefs.getString('numeroMesa');
    _posicaoMesa = prefs.getInt('posicaoMesa');
    notifyListeners();
  }

  void adicionarItem(ItemCarrinho item) {
    final index = _itens.indexWhere((i) => i.idUnico == item.idUnico);
    if (index != -1) {
      _itens[index].quantidade += item.quantidade;
    } else {
      _itens.add(item);
    }
    notifyListeners();
  }

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

  double get total => _itens.fold(0.0, (sum, item) => sum + item.subtotal);

  // PedidoLocalProvider.dart
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
