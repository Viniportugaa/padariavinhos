class Acompanhamento {
  String? id;
  String nome;
  bool disponivel;
  double preco;

  Acompanhamento({
    this.id,
    required this.nome,
    required this.preco,
    this.disponivel = true,
  });

  // Converter objeto para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'disponivel': disponivel,
      'preco': preco,
    };
  }

  // Criar objeto a partir do Map do Firestore
  factory Acompanhamento.fromMap(Map<String, dynamic> map, String id) {
    return Acompanhamento(
      id:  id,
      nome: map['nome'] ?? '',
      preco: (map['preco'] != null)
          ? (map['preco'] as num).toDouble()
          : 0.0,
      disponivel: map['disponivel'] ?? true,
    );
  }
}