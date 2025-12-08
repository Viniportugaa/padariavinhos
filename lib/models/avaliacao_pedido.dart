import 'package:cloud_firestore/cloud_firestore.dart';

class AvaliacaoPedido {
  final String id; // document id (opcional)
  final String pedidoId;
  final String userId;
  final int nota; // 1..5
  final String? comentario;
  final DateTime dataAvaliacao;

  AvaliacaoPedido({
    this.id = '',
    required this.pedidoId,
    required this.userId,
    required this.nota,
    this.comentario,
    required this.dataAvaliacao,
  });

  factory AvaliacaoPedido.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return AvaliacaoPedido(
      id: id,
      pedidoId: map['pedidoId'] ?? '',
      userId: map['userId'] ?? '',
      nota: (map['nota'] as num?)?.toInt() ?? 0,
      comentario: map['comentario'],
      dataAvaliacao: (map['dataAvaliacao'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pedidoId': pedidoId,
      'userId': userId,
      'nota': nota,
      'comentario': comentario,
      'dataAvaliacao': Timestamp.fromDate(dataAvaliacao),
    };
  }
}
