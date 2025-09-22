import 'package:padariavinhos/models/acompanhamento.dart';
import 'produto.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';


class ItemCarrinho {
  final Produto produto;
  double quantidade;
  double preco;
  String? observacao;
  List<Acompanhamento>? acompanhamentos;
  double? precoUnitarioCustom;

  late final String idUnico;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    this.observacao,
    this.acompanhamentos = const [],
    required this.preco,
    this.precoUnitarioCustom,
  }) {
    idUnico = gerarIdUnico();
  }

  double get subtotal {
    final unit = precoUnitarioCustom ??
        PrecoHelper.calcularPrecoUnitario(
            produto: produto, selecionados: acompanhamentos ?? []);
    return unit * quantidade;
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


    return ItemCarrinho(
      produto: produto,
      quantidade: (map['quantidade'] ?? 1).toDouble(),
      observacao: map['observacao'],
      preco: precoItem,
      acompanhamentos: acompanhamentos,
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
    };
  }

  String gerarIdUnico() {
    if (acompanhamentos != null && acompanhamentos!.isNotEmpty) {
      final acompIds = acompanhamentos!.map((a) => a.id).toList()..sort();
      return '${produto.id}-${acompIds.join('-')}';
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

  @override
  bool operator == (Object other) {
    if (identical(this, other)) return true;
    if (other is! ItemCarrinho) return false;

    return produto.id == other.produto.id &&
        observacao == other.observacao &&
        _acompanhamentosIguais(acompanhamentos, other.acompanhamentos);
  }

  @override
  int get hashCode =>
      produto.id.hashCode ^
      (observacao?.hashCode ?? 0) ^
      (acompanhamentos?.fold<int>(0, (prev, a) => prev ^ (a.id?.hashCode ?? 0)) ?? 0);
}
