import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/produto.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage  _storage   = FirebaseStorage.instance;


  /// Faz upload da imagem e retorna a URL
  Future<String> uploadImage(File imageFile) async {
    try{
      final String fileName = const Uuid().v4();
      final snapshot = await _storage
        .ref('produtos/$fileName.jpg')
        .putFile(imageFile);

      return await snapshot.ref.getDownloadURL();
    } catch (e){
      throw Exception("Erro ao fazer upload da imagem: $e");
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> urls = [];
    for (File file in imageFiles) {
      final url = await uploadImage(file);
      urls.add(url);
    }
    return urls;
  }

  Future<void> saveProduct(Produto produto) async {
    try {
      await _firestore.collection('produtos').doc(produto.id).set(produto.toMap());
    } catch (e) {
      throw Exception("Erro ao salvar produto: $e");
    }
  }

  Stream<List<Produto>> streamProdutosDisponiveis() {
    return FirebaseFirestore.instance
        .collection('produtos')
        .where('disponivel', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Produto.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateProduct(Produto produto) async {
    try {
      final docRef = _firestore.collection('produtos').doc(produto.id);

      await docRef.update(produto.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar produto: $e");
    }
  }

  Future<void> alterarDisponibilidade({
    required String produtoId,
    required bool disponivel,
  }) async {
    try {
      await _firestore
          .collection('produtos')
          .doc(produtoId)
          .update({'disponivel': disponivel});
    } catch (e) {
      throw Exception("Erro ao alterar disponibilidade: $e");
    }
  }

  Future<List<Produto>> fetchProdutos() async {
    try {
      final snapshot = await _firestore
          .collection('produtos')
          .where('disponivel', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return Produto.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Erro ao buscar produtos: $e");
    }
  }
}