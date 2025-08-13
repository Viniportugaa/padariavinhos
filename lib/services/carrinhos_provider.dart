import 'package:flutter/material.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import '../models/produto.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class CarrinhoProvider extends ChangeNotifier {
  final List<ItemCarrinho> _itens = [];

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);

  double get total {
    return _itens.fold(0.0, (soma, item) => soma + item.subtotal);
  }

  void adicionar(
      Produto produto,
      int quantidade, {
        String? observacao,
        List<Acompanhamento>? acompanhamentos,
        bool isCombo = false,
        double? precoCombo,
      }) {
    final indexExistente = _itens.indexWhere((item) =>
        item.produto.id == produto.id &&
        item.observacao == observacao &&
        item.isCombo == isCombo &&
        item.precoCombo == precoCombo &&
        _mesmosAcompanhamentos(item.acompanhamentos, acompanhamentos));

    if (indexExistente >= 0) {
      _itens[indexExistente].quantidade += quantidade;
    } else {
      _itens.add(ItemCarrinho(
        produto: produto,
        quantidade: quantidade,
        observacao: observacao,
        acompanhamentos: acompanhamentos,
        isCombo: isCombo,
        precoCombo: precoCombo,
      ));
    }
    notifyListeners();
  }

  void aumentarQuantidadePorIndice(int index) {
    if (index >= 0 && index < _itens.length) {
      _itens[index].quantidade++;
      notifyListeners();
    }
  }

  void diminuirQuantidadePorIndice(int index) {
    if (index >= 0 && index < _itens.length) {
      if (_itens[index].quantidade > 1) {
        _itens[index].quantidade--;
      } else {
        _itens.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removerPorIndice(int index) {
    if (index >= 0 && index < _itens.length) {
      _itens.removeAt(index);
      notifyListeners();
    }
  }

  void atualizarObservacaoPorIndice(int index, String observacao) {
    if (index >= 0 && index < _itens.length) {
      _itens[index].observacao = observacao;
      notifyListeners();
    }
  }

  int _buscarIndicePorProduto({
    required String produtoId,
    String? observacao,
    bool isCombo = false,
    double? precoCombo,
    List<Acompanhamento>? acompanhamentos,
  }) {
    return _itens.indexWhere((item) =>
    item.produto.id == produtoId &&
        item.observacao == observacao &&
        item.isCombo == isCombo &&
        item.precoCombo == precoCombo &&
        _mesmosAcompanhamentos(item.acompanhamentos, acompanhamentos));
  }

  /// Aumenta a quantidade do item pelo produtoId e opções
  void aumentarQuantidade({
    required String produtoId,
    String? observacao,
    bool isCombo = false,
    double? precoCombo,
    List<Acompanhamento>? acompanhamentos,
  }) {
    final index = _buscarIndicePorProduto(
      produtoId: produtoId,
      observacao: observacao,
      isCombo: isCombo,
      precoCombo: precoCombo,
      acompanhamentos: acompanhamentos,
    );
    if (index >= 0) {
      aumentarQuantidadePorIndice(index);
    }
  }

  /// Diminui a quantidade do item pelo produtoId e opções
  void diminuirQuantidade({
    required String produtoId,
    String? observacao,
    bool isCombo = false,
    double? precoCombo,
    List<Acompanhamento>? acompanhamentos,
  }) {
    final index = _buscarIndicePorProduto(
      produtoId: produtoId,
      observacao: observacao,
      isCombo: isCombo,
      precoCombo: precoCombo,
      acompanhamentos: acompanhamentos,
    );
    if (index >= 0) {
      diminuirQuantidadePorIndice(index);
    }
  }

  /// Remove item do carrinho pelo produtoId e opções
  void removerPorProdutoId({
    required String produtoId,
    String? observacao,
    bool isCombo = false,
    double? precoCombo,
    List<Acompanhamento>? acompanhamentos,
  }) {
    final index = _buscarIndicePorProduto(
      produtoId: produtoId,
      observacao: observacao,
      isCombo: isCombo,
      precoCombo: precoCombo,
      acompanhamentos: acompanhamentos,
    );
    if (index >= 0) {
      removerPorIndice(index);
    }
  }

  /// Atualiza a observação do item pelo produtoId e opções
  void atualizarObservacaoPorProdutoId({
    required String produtoId,
    String observacao = '',
    String? observacaoAntiga,
    bool isCombo = false,
    double? precoCombo,
    List<Acompanhamento>? acompanhamentos,
  }) {
    final index = _buscarIndicePorProduto(
      produtoId: produtoId,
      observacao: observacaoAntiga,
      isCombo: isCombo,
      precoCombo: precoCombo,
      acompanhamentos: acompanhamentos,
    );
    if (index >= 0) {
      atualizarObservacaoPorIndice(index, observacao);
    }
  }

  /// Compara se duas listas de acompanhamentos são iguais, ignorando ordem
  bool _mesmosAcompanhamentos(
      List<Acompanhamento>? lista1, List<Acompanhamento>? lista2) {
    if (lista1 == null && lista2 == null) return true;
    if (lista1 == null || lista2 == null) return false;
    if (lista1.length != lista2.length) return false;

    final ids1 = lista1.map((a) => a.id ?? a.nome).toList()..sort();
    final ids2 = lista2.map((a) => a.id ?? a.nome).toList()..sort();

    for (int i = 0; i < ids1.length; i++) {
      if (ids1[i] != ids2[i]) return false;
    }
    return true;
  }

  /// Limpa o carrinho
  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}