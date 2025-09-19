import 'package:firebase_storage/firebase_storage.dart';

Future<String?> getProdutoImageUrl(String path) async {
  try {
    final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
    return url;
  } catch (e) {
    print('Erro ao obter imagem do Firebase Storage: $e');
    return null;
  }
}
