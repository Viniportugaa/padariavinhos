import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/produto.dart';

class FirebaseService {

  Future<void> salvarProduto(Produto produto) async {
    await FirebaseFirestore.instance
        .collection('produtos')
        .add(produto.toMap());
  }
  Future<String?> uploadImagem() async {
    try {
      final imagem = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (imagem == null) return null;

      final File file = File(imagem.path);
      final nomeUnico = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('produtos/$nomeUnico.jpg');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask; // aguarda o upload e captura snapshot
      final url = await snapshot.ref.getDownloadURL();
      return url;

    } on FirebaseException catch (e) {
      print('Erro no upload: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Erro inesperado no upload: $e');
      return null;
    }
  }

}
