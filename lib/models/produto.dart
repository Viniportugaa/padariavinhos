class Produto {
  final String id;
  final String nome;
  final String descricao;
  final List<String> imageUrl;
  final double preco;
  final bool disponivel;
  final String category;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.imageUrl,
    required this.preco,
    required this.disponivel,
    required this.category,
  });

  factory Produto.fromMap(Map<String, dynamic> map, String id) {
    List<String> imagens = [];
    final dynamic imageField = map['imageUrl'];

    if (imageField is String) {
      // Se for String, transformamos em lista com um único elemento
      imagens = [imageField];
    } else if (imageField is List) {
      // Se for lista, garantimos que é List<String>
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'imageUrl': imageUrl,
      'preco': preco,
      'disponivel': disponivel,
    };
  }
}