import 'package:padariavinhos/models/acompanhamento.dart';

import 'produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';

class ItemCarrinho {
  final Produto produto;
  int quantidade;
  String? observacao;
  List<Acompanhamento>? acompanhamentos;

  bool isCombo;
  double? precoCombo;
  List<Produto>? itensCombo;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    this.observacao,
    this.acompanhamentos = const [],
    this.isCombo = false,
    this.precoCombo,
    this.itensCombo,
  });

  double get subtotal {
    double precoBase = isCombo
        ? (precoCombo ?? 0.0)
        : produto.preco;

    double precoAcomp = (!isCombo && acompanhamentos != null)
        ? acompanhamentos!.fold(0.0, (soma, a) => soma + a.preco)
        : 0.0;

    return (precoBase + precoAcomp) * quantidade;
  }

  factory ItemCarrinho.fromMap(Map<String, dynamic> map) {
    return ItemCarrinho(
      produto: Produto.fromMap(map['produto'], map['produtoId']),
      quantidade: map['quantidade'],
      observacao: map['observacao'],
      acompanhamentos: map['acompanhamentos'] != null
           ? (map['acompanhamentos'] as List)
           .map((acompMap) => Acompanhamento.fromMap(acompMap, acompMap['id'] ?? ''))
           .toList()
           : null,
      isCombo: map['isCombo'] ?? false,
      precoCombo: map['precoCombo'] != null ? (map['precoCombo'] as num).toDouble() : null,
      itensCombo: map['itensCombo'] != null
          ? (map['itensCombo'] as List)
          .map((pMap) => Produto.fromMap(pMap, pMap['id']))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produto': produto.toMap(), // salvar produto inteiro
      'produtoId': produto.id,
      'nome': produto.nome,
      'quantidade': quantidade,
      'precoUnitario': produto.preco,
      'observacao': observacao,
      'acompanhamentos': acompanhamentos?.map((a) => a.toMap()).toList(),
      'isCombo': isCombo,
      'precoCombo': precoCombo,
      'itensCombo': itensCombo?.map((p) => p.toMap()).toList(),
    };
  }

  bool _acompanhamentosIguais(List<Acompanhamento>? a, List<Acompanhamento>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  bool operator == (Object other) {
    if (identical(this, other)) return true;
    if (other is! ItemCarrinho) return false;

    return produto.id == other.produto.id &&
        observacao == other.observacao &&
        isCombo == other.isCombo &&
        precoCombo == other.precoCombo &&
        _acompanhamentosIguais(acompanhamentos, other.acompanhamentos) &&
        _itensComboIguais(itensCombo, other.itensCombo);
  }

  bool _itensComboIguais(List<Produto>? a, List<Produto>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      produto.id.hashCode ^
      (observacao?.hashCode ?? 0) ^
      isCombo.hashCode ^
      (precoCombo?.hashCode ?? 0) ^
      (acompanhamentos?.fold<int>(0, (prev, a) => prev ^ (a.id?.hashCode ?? 0)) ?? 0)^
      (itensCombo?.fold<int>(0, (prev, p) => prev ^ (p.id?.hashCode ?? 0)) ?? 0);
}
