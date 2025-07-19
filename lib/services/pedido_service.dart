import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';

class PedidoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> criarPedido(List<CarrinhoItem> itens, {required double total}) {
    final produtos = itens.map((item) => {
      'produtoId': item.produto.id,
      'nome': item.produto.nome,
      'preco': item.produto.preco,
      'quantidade': item.quantidade,
    }).toList();

    return _firestore.collection('pedidos').add({
      'produtos': produtos,
      'total': total,
      'status': 'pendente',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
