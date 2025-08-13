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

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.imageUrl,
    required this.preco,
    required this.disponivel,
    required this.category,
    this.acompanhamentosDisponiveis = const [],
    this.acompanhamentosSelecionados = const [],
    this.acompanhamentosIds = const [],
  });

  factory Produto.fromMap(Map<String, dynamic> map, String id, {List<Acompanhamento>? acompanhamentosDisponiveis, List<Acompanhamento>? acompanhamentosSelecionados}) {
    List<String> imagens = [];
    final dynamic imageField = map['imageUrl'];

    if (imageField is String) {
      imagens = [imageField];
    } else if (imageField is List) {
      imagens = List<String>.from(imageField);
    }

    return Produto(
      id:          id,
      nome:        map['nome'] ?? '',
      descricao:   map['descricao'] ?? '',
      imageUrl: imagens,
      preco:       (map['preco'] ?? 0).toDouble(),
      disponivel:  map['disponivel'] ?? true,
      category: map['category'] ?? '',
      acompanhamentosDisponiveis: acompanhamentosDisponiveis ?? [],
      acompanhamentosSelecionados: acompanhamentosSelecionados ?? [],
      acompanhamentosIds: List<String>.from(map['acompanhamentosIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'imageUrl': imageUrl,
      'preco': preco,
      'disponivel': disponivel,
      'category': category,
      'acompanhamentosDisponiveis': acompanhamentosDisponiveis.map((a) => a.toMap()).toList(),
      'acompanhamentosSelecionados': acompanhamentosSelecionados.map((a) => a.toMap()).toList(),
    };
  }
  Produto copyWith({
    String? id,
    String? nome,
    String? descricao,
    List<String>? imageUrl,
    double? preco,
    bool? disponivel,
    String? category,
    List<Acompanhamento>? acompanhamentosDisponiveis,
    List<Acompanhamento>? acompanhamentosSelecionados,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      imageUrl: imageUrl ?? this.imageUrl,
      preco: preco ?? this.preco,
      disponivel: disponivel ?? this.disponivel,
      category: category ?? this.category,
      acompanhamentosDisponiveis: acompanhamentosDisponiveis ?? this.acompanhamentosDisponiveis,
      acompanhamentosSelecionados: acompanhamentosSelecionados ?? this.acompanhamentosSelecionados,
    );
  }
}