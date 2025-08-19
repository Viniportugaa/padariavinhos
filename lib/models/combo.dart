import 'produto.dart';

class Combo {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final List<String> produtosIds;

  Combo({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.produtosIds,
  });

  factory Combo.fromMap(Map<String, dynamic> map, String id) {
    return Combo(
      id: id,
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      preco: (map['preco'] ?? 0).toDouble(),
      produtosIds: List<String>.from(map['produtosIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'produtosIds': produtosIds,
    };
  }
}