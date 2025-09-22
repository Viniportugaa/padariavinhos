import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Inicializa FCM para o usuário logado
  static Future<void> initFCM(String uid) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(uid, token);
    }

    // Atualiza token automaticamente quando ele mudar
    _fcm.onTokenRefresh.listen((newToken) async {
      await _saveTokenToFirestore(uid, newToken);
    });
  }

  /// Salva token no Firestore de forma única
  static Future<void> _saveTokenToFirestore(String uid, String token) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.set({
      'fcmTokens': FieldValue.arrayUnion([token])
    }, SetOptions(merge: true));
  }
}
