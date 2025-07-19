import 'produto.dart';

class ItemCarrinho {
  final Produto produto;
  int quantidade;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
  });

  double get subtotal => produto.preco * quantidade;

  Map<String, dynamic> toMap() {
    return {
      'produtoId': produto.id,
      'nome': produto.nome,
      'quantidade': quantidade,
      'precoUnitario': produto.preco,
    };
  }
}
