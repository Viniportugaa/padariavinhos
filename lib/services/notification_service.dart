import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Inicializa FCM para um usuário
  static Future<void> initFCM(String uid) async {
    // Solicita permissão (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("🔔 Permissão: ${settings.authorizationStatus}");

    // Salva token atual
    final token = await _messaging.getToken();
    if (token != null) await saveToken(uid, token);

    // Ouve refresh do token
    _messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 Token atualizado: $newToken");
      await saveToken(uid, newToken);
    });
  }

  /// Salva/atualiza token no Firestore
  static Future<void> saveToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('tokens')
        .doc(token)
        .set({
      'created_at': Timestamp.now(),
      'last_used': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
