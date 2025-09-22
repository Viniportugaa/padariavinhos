import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Faz login e retorna role do usuário
  Future<String?> loginWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = userCredential.user;
    if (user == null) throw Exception("Usuário não encontrado");

    // Atualiza FCM
    await NotificationService.initFCM(user.uid);

    // Pega role
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return userDoc.data()?['role'] ?? 'cliente';
  }
}
