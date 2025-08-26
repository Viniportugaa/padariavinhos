import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<bool> isAberto() {
    return _db.collection("config").doc("padaria").snapshots().map(
          (doc) => (doc.data()?["aberto"] ?? false) as bool,
    );
  }

  Future<void> setAberto(bool aberto) async {
    await _db.collection("config").doc("padaria").set({"aberto": aberto});
  }
}
