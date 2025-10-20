import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:intl/intl.dart';

class PedidoLocal {
  final String id;
  final String mesa;
  final int posicao;
  final List<ItemCarrinho> itens;
  final String status;
  final DateTime data;
  final String horaFormatada;
  final String? observacoes;

  PedidoLocal({
    required this.id,
    required this.mesa,
    required this.posicao,
    required this.itens,
    required this.status,
    required this.data,
    required this.horaFormatada,
    this.observacoes,
  });

  /// 🔹 Calcula o total do pedido
  double get total => itens.fold(0.0, (sum, item) => sum + item.subtotal);

  /// 🔹 Retorna o total formatado como moeda
  String get totalFormatado => NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
      .format(total);

  Map<String, dynamic> toMap() {
    return {
      'mesa': mesa,
      'posicao': posicao,
      'status': status,
      'data': Timestamp.fromDate(data),
      'horaFormatada': horaFormatada,
      'observacoes': observacoes ?? '',
      'itens': itens.map((item) => item.toMap()).toList(),
    };
  }

  factory PedidoLocal.fromMap(Map<String, dynamic> map, String id) {
    return PedidoLocal(
      id: id,
      mesa: map['mesa'] ?? '',
      posicao: map['posicao'] ?? 0,
      status: map['status'] ?? 'pendente',
      data: (map['data'] as Timestamp).toDate(),
      horaFormatada: map['horaFormatada'] ?? '',
      observacoes: map['observacoes'] ?? '',
      itens: (map['itens'] as List<dynamic>?)
          ?.map((i) => ItemCarrinho.fromMap(Map<String, dynamic>.from(i)))
          .toList() ??
          [],
    );
  }
}
