import 'package:padariavinhos/models/acompanhamento.dart';
import 'combo.dart';
import 'produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';

class ItemCarrinho {
  final Produto produto;
  final Combo? combo;
  int quantidade;
  String? observacao;
  List<Acompanhamento>? acompanhamentos;

  bool isCombo;
  double? precoCombo;
  List<Produto>? produtosDoCombo;

  Map<String, List<Acompanhamento>>? acompanhamentosPorProduto;

  late final String idUnico;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    this.combo,
    this.observacao,
    this.acompanhamentos = const [],
    this.isCombo = false,
    this.precoCombo,
    this.produtosDoCombo,
    this.acompanhamentosPorProduto,
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
      quantidade: map['quantidade'] ?? 1,
      observacao: map['observacao'],
      acompanhamentos: map['acompanhamentos'] != null
          ? List<Map<String, dynamic>>.from(map['acompanhamentos'])
          .map((acompMap) => Acompanhamento.fromMap(acompMap, acompMap['id'] ?? ''))
          .toList()
          : [],
      isCombo: map['isCombo'] ?? false,
      precoCombo: map['precoCombo'] != null ? (map['precoCombo'] as num).toDouble() : null,
      produtosDoCombo: map['itensCombo'] != null
          ? List<Map<String, dynamic>>.from(map['itensCombo'])
          .map((pMap) => Produto.fromMap(pMap, pMap['id']))
          .toList()
          : null,
      acompanhamentosPorProduto: map['acompanhamentosPorProduto'] != null
          ? (map['acompanhamentosPorProduto'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
          key,
          List<Map<String, dynamic>>.from(value)
              .map((aMap) => Acompanhamento.fromMap(aMap, aMap['id'] ?? ''))
              .toList(),
        ),
      )
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
      'acompanhamentos': acompanhamentos != null
          ? acompanhamentos!.map((a) => a.toMap()).toList()
          : [],
      'isCombo': isCombo,
      'precoCombo': precoCombo,
      'itensCombo': produtosDoCombo != null
          ? produtosDoCombo!.map((p) => p.toMap()).toList()
          : [],
      'acompanhamentosPorProduto': acompanhamentosPorProduto != null
          ? acompanhamentosPorProduto!.map(
            (produtoId, lista) =>
            MapEntry(produtoId, lista.map((a) => a.toMap()).toList()),
      )
          : {},
    };
  }

  String _gerarIdUnico() {
    if (acompanhamentos != null && acompanhamentos!.isNotEmpty) {
      final acompIds = acompanhamentos!.map((a) => a.id).toList()..sort();
      return '${produto.id}-${acompIds.join('-')}';
    }

    if (acompanhamentosPorProduto != null &&
        acompanhamentosPorProduto!.isNotEmpty) {
      final comboIds = acompanhamentosPorProduto!.entries.map((e) {
        final ids = e.value.map((a) => a.id).toList()..sort();
        return '${e.key}:${ids.join(",")}';
      }).toList()
        ..sort();
      return '${produto.id}-${comboIds.join('-')}';
    }

    return produto.id;
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


  bool _acompanhamentosPorProdutoIguais(Map<String, List<Acompanhamento>>? a, Map<String, List<Acompanhamento>>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (var key in a.keys) {
      final listaA = a[key];
      final listaB = b[key];
      if (!_acompanhamentosIguais(listaA, listaB)) return false;
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
        _acompanhamentosPorProdutoIguais(acompanhamentosPorProduto, other.acompanhamentosPorProduto);
  }

  @override
  int get hashCode =>
      produto.id.hashCode ^
      (observacao?.hashCode ?? 0) ^
      isCombo.hashCode ^
      (precoCombo?.hashCode ?? 0) ^
      (acompanhamentos?.fold<int>(0, (prev, a) => prev ^ (a.id?.hashCode ?? 0)) ?? 0)^
      (produtosDoCombo?.fold<int>(0, (prev, p) => prev ^ (p.id?.hashCode ?? 0)) ?? 0);
}
