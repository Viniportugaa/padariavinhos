import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Seleciona múltiplas imagens da galeria e faz upload para o Firebase Storage
  Future<List<String>> selecionarEUploadImagens({String pasta = 'produtos'}) async {
    final List<XFile> imagensSelecionadas = await _picker.pickMultiImage();

    if (imagensSelecionadas.isEmpty) return [];

    List<String> imageUrls = [];

    for (var imagem in imagensSelecionadas) {
      final File file = File(imagem.path);
      final String nomeArquivo = const Uuid().v4();
      final ref = _storage.ref().child('$pasta/$nomeArquivo.jpg');

      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }
}
