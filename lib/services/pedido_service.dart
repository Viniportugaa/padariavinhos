import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:padariavinhos/helpers/date_utils.dart';
import 'package:flutter/material.dart';
class PedidoService {
  final CollectionReference _pedidosRef = FirebaseFirestore.instance.collection('pedidos');
  final DocumentReference _contadorRef = FirebaseFirestore.instance.collection('contadores').doc('pedidoCounter');

  Future<int> getNextNumeroPedido() async {
    return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_contadorRef);

      int current = 0;
      if (snapshot.exists) {
        current = snapshot.get('current') as int;
      }

      final next = current + 1;
      transaction.set(_contadorRef, {'current': next});
      return next;
    });
  }

  Stream<List<Pedido>> streamPedidosUsuario(String userId) {
    return FirebaseFirestore.instance
        .collection('pedidos')
        .where('userId', isEqualTo: userId)
    //.orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => Pedido.fromMap(doc.data(), doc.id))
            .toList());
  }


  Future<void> criarPedido(
      Pedido pedido, {
        DateTime? dataEntrega,
        TimeOfDay? horaEntrega,
      }) async {

    final userRef = FirebaseFirestore.instance.collection('users').doc(pedido.userId);
    final userSnapshot = await userRef.get();
    final userDoc = userSnapshot.data();
    if (userDoc == null) throw Exception('Usuário não encontrado');

    final user = User.fromMap(userDoc);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final contadorSnapshot = await transaction.get(_contadorRef);
      int current = contadorSnapshot.exists ? contadorSnapshot.get('current') as int : 0;
      final next = current + 1;
      transaction.set(_contadorRef, {'current': next});

      final docRef = _pedidosRef.doc();
      final pedidoComId = Pedido(
        id: docRef.id,
        numeroPedido: next,
        userId: pedido.userId,
        nomeUsuario: pedido.nomeUsuario,
        telefone: pedido.telefone,
        itens: pedido.itens,
        status: pedido.status,
        data: pedido.data,
        impresso: pedido.impresso,
        endereco: pedido.endereco,
        formaPagamento:pedido.formaPagamento,
        totalFinal: pedido.totalComFrete,
        frete: pedido.frete,
        tipoEntrega: pedido.tipoEntrega,
        dataHoraEntrega: pedido.dataHoraEntrega,
      );

      transaction.set(docRef, pedidoComId.toMap());
    });
  }
  Future<void> ajustarValorPedido(String pedidoId, double novoValor) async {
    await _pedidosRef.doc(pedidoId).update({
      'totalFinal': novoValor,
      'valorAjustado': true,
    });
  }
}