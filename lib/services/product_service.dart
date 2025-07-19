import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/produto.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage  _storage   = FirebaseStorage.instance;


  /// Faz upload da imagem e retorna a URL
  Future<String> uploadImage(File imageFile, String fileName) async {
    // 1) inicia o upload e aguarda conclusão
    final snapshot = await _storage
        .ref('produtos/$fileName')
        .putFile(imageFile);

    // 2) depois que o upload termina, pega a URL
    return await snapshot.ref.getDownloadURL();

  }

  /// Salva um documento na coleção "produtos"
  Future<void> saveProduct({
    required String nome,
    required String descricao,
    required double preco,
    required List<String> imageUrl,
    required bool disponivel,
    required String category,
  }) {
    final doc = _firestore.collection('produtos').doc();
    return doc.set({
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'imageUrl': imageUrl,
      'disponivel': disponivel,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> alterarDisponibilidade({
    required String produtoId,
    required bool disponivel,
  }) {
    return _firestore
        .collection('produtos')
        .doc(produtoId)
        .update({'disponivel': disponivel});
  }

  Future<List<Produto>> fetchProdutos() async {
    final snapshot = await _firestore
        .collection('produtos')
        .where('disponivel', isEqualTo: true)  // filtra só os disponíveis
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Produto.fromMap(data, doc.id);
    }).toList();
  }

}