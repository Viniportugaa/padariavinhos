import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../models/produto.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage  _storage   = FirebaseStorage.instance;


  Future<String> uploadImage(dynamic imageSource) async {
    try {
      final String fileName = const Uuid().v4();
      final Reference ref = _storage.ref().child('produtos/$fileName.jpg');

      UploadTask uploadTask;

      if (kIsWeb) {
        if (imageSource is Uint8List) {
          uploadTask = ref.putData(
            imageSource,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          throw Exception("Formato de imagem inválido para Web");
        }
      } else {
        if (imageSource is File) {
          uploadTask = ref.putFile(imageSource);
        } else {
          throw Exception("Formato de imagem inválido para Mobile");
        }
      }

      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      developer.log("Erro ao enviar imagem: $e");
      throw Exception("Erro ao fazer upload da imagem: $e");
    }
  }


  Future<List<String>> uploadMultipleImages(List<dynamic> imageFiles) async {
    List<String> urls = [];

    for (var file in imageFiles) {
      try {
        final url = await uploadImage(file);
        urls.add(url);
      } catch (e) {
        developer.log('Erro ao enviar imagem: $e');
      }
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