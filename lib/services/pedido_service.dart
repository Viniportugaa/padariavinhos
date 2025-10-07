import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/cupom.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PedidoService {
  final CollectionReference _pedidosRef =
  FirebaseFirestore.instance.collection('pedidos');
  final DocumentReference _contadorRef = FirebaseFirestore.instance
      .collection('contadores')
      .doc('pedidoCounter');
  final CollectionReference _cuponsRef =
  FirebaseFirestore.instance.collection('cupons');

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
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// 🔹 Criar pedido com suporte a cupom
  Future<void> criarPedido(
      Pedido pedido, {
        DateTime? dataEntrega,
        TimeOfDay? horaEntrega,
      }) async {
    try {
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

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          throw Exception("Usuário não autenticado");
        }

        final pedidoComId = Pedido(
          id: docRef.id,
          numeroPedido: next,
          userId: uid,
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
          cupomAplicado: pedido.cupomAplicado,

        );

        // 🔹 debug antes de salvar
        debugPrint("📦 Salvando pedido: ${pedidoComId.toMap()}");

        transaction.set(docRef, pedidoComId.toMap());

        // 6️⃣ Marca cupom como usado (se houver)
        if (pedido.cupomAplicado != null) {
          final cupom = pedido.cupomAplicado!;
          final cupomRef = _cuponsRef.doc(cupom.id);

          transaction.update(cupomRef, {
            'usuariosUsaram': FieldValue.arrayUnion([uid]),
          });
        }
      });

      debugPrint("✅ Pedido criado com sucesso!");
    } catch (e, stack) {
      debugPrint("❌ Tipo do erro: ${e.runtimeType}");
      debugPrint("❌ Detalhes: $e");
      debugPrint("📌 Stack trace: $stack");

      throw Exception("Erro ao criar pedido: $e");
    }
  }

  Future<void> ajustarValorPedido(String pedidoId, double novoValor) async {
    await _pedidosRef.doc(pedidoId).update({
      'totalFinal': novoValor,
      'valorAjustado': true,
    });
  }
}
