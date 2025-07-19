import 'package:flutter/material.dart';
import '../models/produto.dart';

class CarrinhoProvider extends ChangeNotifier {
  final Map<String, CarrinhoItem> _itens = {};

  Map<String, CarrinhoItem> get itens => _itens;

  double get total {
    return _itens.values
        .fold(0.0, (soma, item) => soma + (item.produto.preco * item.quantidade));
  }

  void adicionar(Produto produto, int quantidade) {
    if (_itens.containsKey(produto.id)) {
      _itens[produto.id]!.quantidade += quantidade;
    } else {
      _itens[produto.id] = CarrinhoItem(produto: produto, quantidade: quantidade);
    }
    notifyListeners();
  }
  void aumentarQuantidade(String produtoId) {
    if (_itens.containsKey(produtoId)) {
      _itens[produtoId]!.quantidade++;
      notifyListeners();
    }
  }

  void diminuirQuantidade(String produtoId) {
    if (_itens.containsKey(produtoId)) {
      if (_itens[produtoId]!.quantidade > 1) {
        _itens[produtoId]!.quantidade--;
      } else {
        _itens.remove(produtoId); // remove se for 1 e tentar reduzir
      }
      notifyListeners();
    }
  }

  void remover(String produtoId) {
    _itens.remove(produtoId);
    notifyListeners();
  }

  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}

class CarrinhoItem {
  final Produto produto;
  int quantidade;

  CarrinhoItem({required this.produto, this.quantidade = 1});
}
