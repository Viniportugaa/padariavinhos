import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:flutter/material.dart';

class PedidoService {
  final CollectionReference _pedidosRef =
  FirebaseFirestore.instance.collection('pedidos');
  final DocumentReference _contadorRef = FirebaseFirestore.instance
      .collection('contadores')
      .doc('pedidoCounter');

  Future<int> getNextNumeroPedido() async {
    return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_contadorRef);
      int current = snapshot.exists ? (snapshot.get('current') as int) : 0;
      final next = current + 1;
      transaction.set(_contadorRef, {'current': next});
      return next;
    });
  }

  Stream<List<Pedido>> streamPedidosUsuario(String userId) {
    return _pedidosRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> criarPedido(Pedido pedido, {DateTime? dataEntrega, TimeOfDay? horaEntrega}) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final contadorSnapshot = await transaction.get(_contadorRef);
      int current =
      contadorSnapshot.exists ? (contadorSnapshot.get('current') as int) : 0;
      final next = current + 1;
      transaction.set(_contadorRef, {'current': next});

      final docRef = _pedidosRef.doc();

      DateTime? dataHoraEntrega;
      if (dataEntrega != null && horaEntrega != null) {
        dataHoraEntrega = DateTime(
          dataEntrega.year,
          dataEntrega.month,
          dataEntrega.day,
          horaEntrega.hour,
          horaEntrega.minute,
        );
      } else {
        dataHoraEntrega = pedido.dataHoraEntrega;
      }

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
        formaPagamento: pedido.formaPagamento,
        frete: pedido.frete,
        totalFinal: pedido.totalFinal,
        tipoEntrega: pedido.tipoEntrega,
        dataHoraEntrega: dataHoraEntrega,
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
