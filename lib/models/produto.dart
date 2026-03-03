import 'acompanhamento.dart';

class Produto {
  final String id;
  final String nome;
  final String descricao;
  final List<String> imageUrl;
  final double preco;
  final bool disponivel;
  final String category;

  final List<Acompanhamento> acompanhamentosDisponiveis;
  final List<Acompanhamento> acompanhamentosSelecionados;
  final List<String> acompanhamentosIds;
  final bool vendidoPorPeso;
  final bool disponivelLocal;
  final List<String> diasDisponiveis;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.imageUrl,
    required this.preco,
    required this.disponivel,
    required this.category,
    this.disponivelLocal = true,
    this.acompanhamentosDisponiveis = const [],
    this.acompanhamentosSelecionados = const [],
    this.acompanhamentosIds = const [],
    this.vendidoPorPeso = false,
    this.diasDisponiveis = const ["all"],

  });

  Produto copyWith({
    String? id,
    String? nome,
    String? descricao,
    List<String>? imageUrl,
    double? preco,
    bool? disponivel,
    String? category,
    bool? disponivelLocal,
    List<Acompanhamento>? acompanhamentosDisponiveis,
    List<Acompanhamento>? acompanhamentosSelecionados,
    List<String>? acompanhamentosIds,
    bool? vendidoPorPeso,
    List<String>? diasDisponiveis,

  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      imageUrl: imageUrl ?? List.from(this.imageUrl),
      preco: preco ?? this.preco,
      disponivel: disponivel ?? this.disponivel,
      category: category ?? this.category,
      disponivelLocal: disponivelLocal ?? this.disponivelLocal,
      acompanhamentosDisponiveis:
      acompanhamentosDisponiveis ?? List.from(this.acompanhamentosDisponiveis),
      acompanhamentosSelecionados:
      acompanhamentosSelecionados ?? List.from(this.acompanhamentosSelecionados),
      acompanhamentosIds: acompanhamentosIds ?? List.from(this.acompanhamentosIds),
      vendidoPorPeso: vendidoPorPeso ?? this.vendidoPorPeso,
      diasDisponiveis: diasDisponiveis ?? List.from(this.diasDisponiveis),

    );
  }

  factory Produto.fromMap(Map<String, dynamic> map, String id, {List<Acompanhamento>? acompanhamentosDisponiveis, List<Acompanhamento>? acompanhamentosSelecionados}) {
    final dynamic imgField = map['imageUrl'];

    final List<String> imagens = imgField is List
        ? List<String>.from(imgField)
        : imgField is String && imgField.isNotEmpty
        ? [imgField]
        : [];

    return Produto(
      id:          id,
      nome:        map['nome'] ?? '',
      descricao:   map['descricao'] ?? '',
      imageUrl: imagens,
      preco:       (map['preco'] ?? 0).toDouble(),
      disponivel:  map['disponivel'] ?? true,
      disponivelLocal: map['disponivelLocal'] ?? true,
      category: map['category'] ?? '',
      acompanhamentosDisponiveis: acompanhamentosDisponiveis ?? [],
      acompanhamentosSelecionados: acompanhamentosSelecionados ?? [],
      acompanhamentosIds: List<String>.from(map['acompanhamentosIds'] ?? []),
      vendidoPorPeso: map['vendidoPorPeso'] ?? false,
      diasDisponiveis:
      (map['diasDisponiveis'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          ["all"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'imageUrl': imageUrl,
      'preco': preco,
      'disponivel': disponivel,
      'disponivelLocal': disponivelLocal,
      'category': category,
      'acompanhamentosDisponiveis': acompanhamentosDisponiveis.map((a) => a.toMap()).toList(),
      'acompanhamentosSelecionados': acompanhamentosSelecionados.map((a) => a.toMap()).toList(),
      'vendidoPorPeso': vendidoPorPeso,
      'diasDisponiveis': diasDisponiveis,
    };
  }
}