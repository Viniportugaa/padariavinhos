import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoListenerService {
  final FirebaseFirestore _db;

  PedidoListenerService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Retorna stream com lista de dados brutos dos pedidos (incluindo id e status)
  Stream<List<Map<String, dynamic>>> listenPedidos(String userId) {
    return _db
        .collection('pedidos')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }
}
