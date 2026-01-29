import 'package:padariavinhos/models/acompanhamento.dart';
import 'produto.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemCarrinho {
  final Produto produto;
  double quantidade;
  double preco;
  String? observacao;
  List<Acompanhamento>? acompanhamentos;
  double? precoUnitarioCustom;

  late final String idUnico;

  final String? mesa;
  final int? posicao;

  // Novo status individual do item
  String status;

  // Item já foi enviado para a cozinha?
  bool enviadoParaCozinha;

  // Datas importantes
  DateTime? dataCriado;
  DateTime? dataStatusAlterado;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    this.observacao,
    this.acompanhamentos = const [],
    required this.preco,
    this.precoUnitarioCustom,
    this.mesa,
    this.posicao,
    this.dataCriado,
    // 🆕 novos campos
    this.status = "pendente",
    this.enviadoParaCozinha = false,
    this.dataStatusAlterado,
  }) {
    idUnico = gerarIdUnico();
    this.dataCriado = dataCriado ?? DateTime.now();
  }

  // 🔥 Cria o ItemCarrinho diretamente do Firestore
  factory ItemCarrinho.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemCarrinho.fromMap(data);
  }



  // 🔹 Subtotal calculado dinamicamente
  double get subtotal {
    final unit = precoUnitarioCustom ??
        PrecoHelper.calcularPrecoUnitario(
          produto: produto,
          selecionados: acompanhamentos ?? [],
        );
    return unit * quantidade;
  }

  /// ==========================================================================================
  /// 🔥 FIRESTORE: FROM MAP
  /// ==========================================================================================
  factory ItemCarrinho.fromMap(Map<String, dynamic> map) {
    // Produto
    final produto = Produto.fromMap(map['produto'], map['produtoId']);

    // Preço
    final precoItem = (map['preco'] != null)
        ? (map['preco'] as num).toDouble()
        : produto.preco;

    // Acompanhamentos
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
      precoUnitarioCustom: map['precoUnitario'] != null
          ? (map['precoUnitario'] as num).toDouble()
          : null,
      mesa: map['mesa'] as String?,
      posicao: map['posicao'] != null ? (map['posicao'] as num).toInt() : null,
      status: map['status'] ?? "pendente",
      enviadoParaCozinha: map['enviadoParaCozinha'] ?? false,
      dataCriado: (map['dataCriado'] as Timestamp?)?.toDate(),
      dataStatusAlterado:
      (map['dataStatusAlterado'] as Timestamp?)?.toDate(),
    );
  }

  void atualizarStatus(String novoStatus) {
    status = novoStatus;
    dataStatusAlterado = DateTime.now();
  }

  /// ==========================================================================================
  /// 🔥 FIRESTORE: TO MAP
  /// ==========================================================================================
  Map<String, dynamic> toMap() {
    return {
      'produto': produto.toMap(),
      'produtoId': produto.id,
      'nome': produto.nome,
      'quantidade': quantidade,
      'preco': preco,
      'precoUnitario': precoUnitarioCustom,
      'subtotal': subtotal,
      'observacao': observacao,
      'acompanhamentos': acompanhamentos != null
          ? acompanhamentos!.map((a) => a.toMap()).toList()
          : [],
      'mesa': mesa,
      'posicao': posicao,
    };
  }

  /// ==========================================================================================
  /// 🔹 Lógica para gerar ID único baseado em acompanhamentos
  /// ==========================================================================================
  String gerarIdUnico() {
    if (acompanhamentos != null && acompanhamentos!.isNotEmpty) {
      final acompIds = acompanhamentos!.map((a) => a.id).toList()..sort();
      return '${produto.id}-${acompIds.join('-')}';
    }
    return produto.id;
  }

  bool _acompanhamentosIguais(
      List<Acompanhamento>? a, List<Acompanhamento>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }



  @override
  bool operator ==(Object other) {
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
      (acompanhamentos?.fold<int>(
          0, (prev, a) => prev ^ (a.id?.hashCode ?? 0)) ??
          0);
}
