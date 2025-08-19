import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Pedido {
  final int numeroPedido;
  final String id;
  final String userId;
  final String nomeUsuario;
  final String telefone;
  final List<ItemCarrinho> itens;
  final double total;
  final String status;
  final DateTime data;
  final bool impresso;
  final String endereco;
  final List<String> formaPagamento;


  Pedido({
    required this.id,
    required this.numeroPedido,
    required this.userId,
    required this.nomeUsuario,
    required this.telefone,
    required this.itens,
    required this.total,
    required this.status,
    required this.data,
    this.impresso = false,
    required this.endereco,
    required this.formaPagamento,

  });

  factory Pedido.fromMap(Map<String, dynamic> map, String id) {
    return Pedido(
      id: id,
      numeroPedido: map['numeroPedido'] ?? 0,
      userId: map['userId'] ?? '',
      nomeUsuario: map['nomeUsuario'] ?? 'Desconhecido',
      telefone: map['telefone'] ?? 'Sem telefone',
      itens: (map['itens'] as List<dynamic>? ?? [])
          .map((e) => ItemCarrinho.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (map['total'] != null)
          ? (map['total'] as num).toDouble()
          : 0.0,
      status: map['status'] ?? 'pendente',
      data: (map['data'] is Timestamp)
          ? (map['data'] as Timestamp).toDate()
          : DateTime.now(),
      impresso: map['impresso'] ?? false,
      endereco: map['endereco'] ?? 'Sem endereço',
      formaPagamento: List<String>.from(map['formaPagamento'] ?? ['Pix']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numeroPedido': numeroPedido,
      'userId': userId,
      'nomeUsuario': nomeUsuario,
      'telefone': telefone,
      'itens': itens.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'data': Timestamp.fromDate(data),
      'impresso': impresso,
      'endereco': endereco,
      'formaPagamento': formaPagamento,
    };
  }
}