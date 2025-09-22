import 'package:flutter/material.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import '../models/produto.dart';
import '../models/acompanhamento.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';

class CarrinhoProvider extends ChangeNotifier {
  final List<ItemCarrinho> _itens = [];

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);

  double get total => _itens.fold(0.0, (soma, item) {
    final precoUnitario = PrecoHelper.calcularPrecoUnitario(
      produto: item.produto,
      selecionados: item.acompanhamentos,
    );
    return soma + precoUnitario * item.quantidade;
  });
  // ================== ADICIONAR PRODUTO ==================
  void adicionarProduto(
      Produto produto,
      double quantidade, {
        String? observacao,
        List<Acompanhamento>? acompanhamentos,

      }) {
    final indexExistente = _itens.indexWhere((item) =>
    item.produto.id == produto.id &&
        item.observacao == observacao &&
        _acompanhamentosIguais(item.acompanhamentos, acompanhamentos));
    final precoUnitario = PrecoHelper.calcularPrecoUnitario(
      produto: produto,
      selecionados: acompanhamentos ?? [],
    );
    if (indexExistente >= 0) {
      _itens[indexExistente].quantidade += quantidade;
    } else {
      final novoItem = ItemCarrinho(
        produto: produto,
        quantidade: quantidade,
        observacao: observacao,
        acompanhamentos: acompanhamentos ?? [],
        preco: precoUnitario,
      );
      _itens.add(novoItem);
    }

    notifyListeners();
  }

  // ================== QUANTIDADE ==================
  void aumentarQuantidade(int index) {
    if (index >= 0 && index < _itens.length) {
      _itens[index].quantidade++;
      notifyListeners();
    }
  }

  void diminuirQuantidade(int index) {
    if (index >= 0 && index < _itens.length) {
      if (_itens[index].quantidade > 1) {
        _itens[index].quantidade--;
      } else {
        _itens.removeAt(index);
      }
      notifyListeners();
    }
  }

  // ================== REMOVER ==================
  void removerPorIndice(int index) {
    if (index >= 0 && index < _itens.length) {
      _itens.removeAt(index);
      notifyListeners();
    }
  }

  void removerPorProdutoId({
    required String produtoId,
    String? observacao,
    List<Acompanhamento>? acompanhamentos,

  }) {
    final index = _itens.indexWhere((item) =>
    item.produto.id == produtoId &&
        item.observacao == observacao &&
        _acompanhamentosIguais(item.acompanhamentos, acompanhamentos));
    if (index >= 0) {
      removerPorIndice(index);
    }
  }

  // ================== ATUALIZAR ==================
  void atualizarObservacao(int index, String observacao) {
    if (index >= 0 && index < _itens.length) {
      _itens[index].observacao = observacao;
      notifyListeners();
    }
  }

  void atualizarObservacaoPorProdutoId({
    required String produtoId,
    required String observacao,
    String? observacaoAntiga,
    List<Acompanhamento>? acompanhamentos,

  }) {
    final index = _itens.indexWhere((item) =>
    item.produto.id == produtoId &&
        item.observacao == observacaoAntiga &&
        _acompanhamentosIguais(item.acompanhamentos, acompanhamentos));
    if (index >= 0) {
      atualizarObservacao(index, observacao);
    }
  }

  void atualizarAcompanhamentos(
      int index, List<Acompanhamento> acompanhamentos) {
    if (index >= 0 && index < _itens.length) {
      _itens[index].acompanhamentos = List.from(acompanhamentos);
      notifyListeners();
    }
  }

  void atualizarAcompanhamentosPorProdutoId({
    required String produtoId,
    List<Acompanhamento>? acompanhamentos,

    String? observacao,
  }) {
    final index = _itens.indexWhere((item) =>
    item.produto.id == produtoId &&
        item.observacao == observacao);
    if (index >= 0 && acompanhamentos != null) {
      atualizarAcompanhamentos(index, acompanhamentos);
    }
  }

  // ================== UTILITÁRIOS ==================
  bool _acompanhamentosIguais(
      List<Acompanhamento>? a, List<Acompanhamento>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    final sortedA = a.map((e) => e.id).toList()..sort();
    final sortedB = b.map((e) => e.id).toList()..sort();

    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }


  void limpar() {
    _itens.clear();
    notifyListeners();
  }
}
