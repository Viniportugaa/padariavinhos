class Pedido {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> itens;
  final double total;
  final DateTime data;

  Pedido({
    required this.id,
    required this.userId,
    required this.itens,
    required this.total,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'itens': itens,
      'total': total,
      'data': data,
    };
  }
}