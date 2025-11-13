import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../models/produto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage  _storage   = FirebaseStorage.instance;

  Future<String> uploadImage(dynamic imageSource) async {
    try {
      final String fileName = const Uuid().v4();
      final Reference ref = _storage.ref().child('produtos/$fileName.jpg');

      UploadTask uploadTask;

      // 🧠 Função auxiliar para compressão universal
      Future<Uint8List> _compressBytes(Uint8List bytes) async {
        try {
          final result = await FlutterImageCompress.compressWithList(
            bytes,
            quality: 75, // ajuste entre 50–90 conforme desejar
            minWidth: 800, // reduz grandes imagens mantendo nitidez
            minHeight: 800,
            format: CompressFormat.jpeg,
          );
          return Uint8List.fromList(result);
        } catch (e) {
          developer.log("Falha ao comprimir imagem: $e");
          return bytes; // fallback: retorna original
        }
      }

      if (kIsWeb) {
        // 🖼️ Web / PWA
        Uint8List bytes;
        if (imageSource is Uint8List) {
          bytes = imageSource;
        } else {
          // Caso seja XFile, lê os bytes
          bytes = await (imageSource as dynamic).readAsBytes();
        }

        // 🔄 Comprime antes do upload
        final compressed = await _compressBytes(bytes);

        uploadTask = ref.putData(
          compressed,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // 📱 Android / iOS
        if (imageSource is File) {
          final bytes = await imageSource.readAsBytes();
          final compressed = await _compressBytes(bytes);
          uploadTask = ref.putData(
            compressed,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          throw Exception("Formato de imagem inválido para Mobile");
        }
      }

      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      developer.log("Erro ao enviar imagem: $e");
      throw Exception("Erro ao fazer upload da imagem: $e");
    }
  }

  Future<List<String>> uploadMultipleImages(List<dynamic> imageFiles) async {
    try {
      // Executa todos os uploads em paralelo para otimizar tempo total
      final List<Future<String>> uploadTasks = imageFiles.map((file) async {
        try {
          return await uploadImage(file);
        } catch (e) {
          developer.log('Erro ao enviar imagem: $e');
          return ''; // retorna vazio se falhar (será filtrado depois)
        }
      }).toList();

      // Aguarda todos terminarem simultaneamente
      final List<String> urls = await Future.wait(uploadTasks);

      // Remove URLs vazias (de uploads que falharam)
      return urls.where((url) => url.isNotEmpty).toList();
    } catch (e) {
      developer.log('Erro geral ao enviar múltiplas imagens: $e');
      throw Exception('Erro ao enviar múltiplas imagens: $e');
    }
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