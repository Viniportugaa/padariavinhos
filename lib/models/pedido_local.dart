import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class PedidoLocal {
  final String id;
  final String mesa;
  final int posicao;
  final List<ItemCarrinho> itens;
  final String status;
  final DateTime data;
  final String horaFormatada;
  final String? observacoes;
  final double total;

  PedidoLocal({
    required this.id,
    required this.mesa,
    required this.posicao,
    required this.itens,
    required this.status,
    required this.data,
    required this.horaFormatada,
    required this.total,
    this.observacoes,
  });

  /// 🔹 Total formatado
  String get totalFormatado =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(total);

  /// 🔹 Converter para Firestore
  Map<String, dynamic> toMap() {
    return {
      'mesa': mesa,
      'posicao': posicao,
      'status': status,
      'data': Timestamp.fromDate(data),
      'horaFormatada': horaFormatada,
      'observacoes': observacoes ?? '',
      'total': total,
      'itens': itens.map((item) => item.toMap()).toList(),
    };
  }

  /// 🔹 Criar pedido a partir do documento principal
  factory PedidoLocal.fromMap(Map<String, dynamic> map, String id) {
    return PedidoLocal(
      id: id,
      mesa: map['mesa']?.toString() ?? '',
      posicao: map['posicao'] ?? 0,
      status: map['status'] ?? 'pendente',
      data: (map['data'] as Timestamp).toDate(),
      horaFormatada: map['horaFormatada'] ?? '',
      observacoes: map['observacoes'] ?? '',
      total: (map['total'] ?? 0).toDouble(),
      itens: const [], // carregados depois
    );
  }

  /// 🔹 Criar a partir do Firestore (DOC SNAPSHOT)
  factory PedidoLocal.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return PedidoLocal.fromMap(map, doc.id);
  }

  /// 🔹 Carregar itens da subcoleção
  static Future<List<ItemCarrinho>> carregarItens(String pedidoId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pedidos_local')
        .doc(pedidoId)
        .collection('itens')
        .get();

    return snapshot.docs
        .map((doc) => ItemCarrinho.fromMap(doc.data()))
        .toList();
  }
}
