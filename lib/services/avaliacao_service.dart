import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/avaliacao_pedido.dart';

class AvaliacaoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Salva avaliação e retorna o document id gerado
  Future<String> salvarAvaliacao(AvaliacaoPedido avaliacao) async {
    final doc = await _db.collection('avaliacoes').add(avaliacao.toMap());
    return doc.id;
  }

  /// Marca pedido como avaliado
  Future<void> marcarPedidoAvaliado(String pedidoId) async {
    await _db.collection('pedidos').doc(pedidoId).update({'foiAvaliado': true});
  }

  /// Retorna média e quantidade de avaliações de um pedido
  Future<Map<String, dynamic>> obterMediaPorPedido(String pedidoId) async {
    final q = await _db.collection('avaliacoes').where('pedidoId', isEqualTo: pedidoId).get();
    if (q.docs.isEmpty) return {'media': 0.0, 'count': 0};
    final notas = q.docs.map((d) => (d.data()['nota'] as num).toDouble()).toList();
    final media = notas.reduce((a, b) => a + b) / notas.length;
    return {'media': media, 'count': notas.length};
  }

  /// (Opcional) busca avaliações para painel admin
  Stream<List<AvaliacaoPedido>> streamAvaliacoes({int limit = 50}) {
    return _db.collection('avaliacoes')
        .orderBy('dataAvaliacao', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AvaliacaoPedido.fromMap(d.data(), id: d.id)).toList());
  }
}
