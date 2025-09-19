import 'package:padariavinhos/models/acompanhamento.dart';
import 'produto.dart';

class ItemCarrinho {
  final Produto produto;
  double quantidade;
  double preco;
  String? observacao;
  List<Acompanhamento>? acompanhamentos;
  double? precoUnitarioCustom;


  Map<String, List<Acompanhamento>>? acompanhamentosPorProduto;

  late final String idUnico;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    this.observacao,
    this.acompanhamentos = const [],
    required this.preco,
    this.precoUnitarioCustom,
    this.acompanhamentosPorProduto,
  }) {
    idUnico = gerarIdUnico();
  }

  double get subtotal {
    final valorAcomp = _calcularValorAcompanhamentos();
    final precoUnitario = precoUnitarioCustom ?? preco;
    return (precoUnitario * quantidade) + valorAcomp;
  }

  double _calcularValorAcompanhamentos() {
    if (produto.category == 'Pratos') {
      return valorAcompanhamentosPratos;
    }

    if (acompanhamentos != null && acompanhamentos!.isNotEmpty) {
      return acompanhamentos!.fold(0.0, (soma, a) => soma + a.preco);
    }

    return 0.0;
  }

  double get valorAcompanhamentosPratos {
    if (produto.category != 'Pratos' ||
        acompanhamentos == null ||
        acompanhamentos!.isEmpty) {
      return 0.0;
    }

    if (acompanhamentos!.length <= 3) return 0.0;

    final sortedPrecos = acompanhamentos!.map((a) => a.preco).toList()..sort();
    final extras = sortedPrecos.skip(3).toList();
    return extras.fold(0.0, (soma, preco) => soma + preco);
  }

  factory ItemCarrinho.fromMap(Map<String, dynamic> map) {
    // Cria o produto primeiro
    final produto = Produto.fromMap(map['produto'], map['produtoId']);

    // Define o preço do item: se houver 'preco' salvo, usa, senão pega do produto
    final precoItem = (map['preco'] != null)
        ? (map['preco'] as num).toDouble()
        : produto.preco;

    // Cria a lista de acompanhamentos
    final acompanhamentos = map['acompanhamentos'] != null
        ? List<Map<String, dynamic>>.from(map['acompanhamentos'])
        .map((acompMap) =>
        Acompanhamento.fromMap(acompMap, acompMap['id'] ?? ''))
        .toList()
        : <Acompanhamento>[];

    // Cria o mapa de acompanhamentos por produto
    final acompanhamentosPorProduto = map['acompanhamentosPorProduto'] != null
        ? (map['acompanhamentosPorProduto'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
        key,
        List<Map<String, dynamic>>.from(value)
            .map((aMap) => Acompanhamento.fromMap(aMap, aMap['id'] ?? ''))
            .toList(),
      ),
    )
        : null;

    return ItemCarrinho(
      produto: produto,
      quantidade: (map['quantidade'] ?? 1).toDouble(),
      observacao: map['observacao'],
      preco: precoItem,
      acompanhamentos: acompanhamentos,
      acompanhamentosPorProduto: acompanhamentosPorProduto,
      precoUnitarioCustom: (map['precoUnitarioCustom'] != null)
          ? (map['precoUnitarioCustom'] as num).toDouble()
          : null,
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'produto': produto.toMap(),
      'produtoId': produto.id,
      'nome': produto.nome,
      'quantidade': quantidade,
      'preco': preco,
      'precoUnitario': precoUnitarioCustom,
      'observacao': observacao,
      'acompanhamentos': acompanhamentos != null
          ? acompanhamentos!.map((a) => a.toMap()).toList()
          : [],
      'acompanhamentosPorProduto': acompanhamentosPorProduto != null
          ? acompanhamentosPorProduto!.map(
            (produtoId, lista) =>
            MapEntry(produtoId, lista.map((a) => a.toMap()).toList()),
      )
          : {},
    };
  }

  String gerarIdUnico() {
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
        _acompanhamentosIguais(acompanhamentos, other.acompanhamentos) &&
        _acompanhamentosPorProdutoIguais(acompanhamentosPorProduto, other.acompanhamentosPorProduto);
  }

  @override
  int get hashCode =>
      produto.id.hashCode ^
      (observacao?.hashCode ?? 0) ^
      (acompanhamentos?.fold<int>(0, (prev, a) => prev ^ (a.id?.hashCode ?? 0)) ?? 0);
}
