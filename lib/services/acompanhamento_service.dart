import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/acompanhamento.dart';

class AcompanhamentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Salva um acompanhamento (novo ou existente)
  Future<void> salvarAcompanhamento(Acompanhamento acompanhamento) async {
    if (acompanhamento.id != null && acompanhamento.id!.isNotEmpty) {
      // Atualiza
      await _firestore
          .collection('acompanhamentos')
          .doc(acompanhamento.id)
          .update(acompanhamento.toMap());
    } else {
      // Cria novo
      await _firestore.collection('acompanhamentos').add(acompanhamento.toMap());
    }
  }

  /// Busca todos os acompanhamentos disponíveis
  Future<List<Acompanhamento>> buscarAcompanhamentosDisponiveis() async {
    final snapshot = await _firestore
        .collection('acompanhamentos')
        .where('disponivel', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => Acompanhamento.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Busca todos os acompanhamentos (independente da disponibilidade)
  Future<List<Acompanhamento>> buscarTodos() async {
    final snapshot = await _firestore.collection('acompanhamentos').get();

    return snapshot.docs
        .map((doc) => Acompanhamento.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Deleta um acompanhamento pelo id
  Future<void> deletarAcompanhamento(String id) async {
    await _firestore.collection('acompanhamentos').doc(id).delete();
  }

  /// Altera a disponibilidade de um acompanhamento
  Future<void> alterarDisponibilidade({
    required String acompanhamentoId,
    required bool disponivel,
  }) async {
    await _firestore
        .collection('acompanhamentos')
        .doc(acompanhamentoId)
        .update({'disponivel': disponivel});
  }
}
