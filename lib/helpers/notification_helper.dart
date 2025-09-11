import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicializa FCM: pede permissão, registra token e ouve refresh
  static Future<void> initFCM(String uid) async {
    // 1️⃣ Solicita permissão (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("🔔 Permissão de notificações: ${settings.authorizationStatus}");

    // 2️⃣ Obtém token atual e salva
    final token = await _messaging.getToken();
    if (token != null) {
      await saveToken(uid, token);
    }

    // 3️⃣ Ouve mudanças de token (refresh)
    _messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 FCM Token atualizado: $newToken");
      await saveToken(uid, newToken);
    });
  }

  /// Salva/atualiza token no Firestore
  static Future<void> saveToken(String uid, String token) async {
    final userRef = _firestore.collection('users').doc(uid);

    await userRef.collection('tokens').doc(token).set({
      'created_at': Timestamp.now(),
      'last_used': Timestamp.now(),
    }, SetOptions(merge: true));

    print("✅ FCM Token salvo no Firestore: $token");
  }

  /// Atualiza last_used (opcional, útil para saber qual token é mais recente)
  static Future<void> touchToken(String uid, String token) async {
    final docRef = _firestore.collection('users').doc(uid).collection('tokens').doc(token);
    await docRef.update({'last_used': Timestamp.now()});
  }

  /// Remove tokens inválidos
  static Future<void> cleanInvalidTokens(String uid, List<String> invalidTokens) async {
    final userRef = _firestore.collection('users').doc(uid);

    for (var token in invalidTokens) {
      await userRef.collection('tokens').doc(token).delete();
      print("🗑 Token inválido removido: $token");
    }
  }

  /// Mostra notificação recebida quando app está em foreground
  static void listenForegroundNotifications(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Nova notificação';
      final body = message.notification?.body ?? '';

      // Exemplo: SnackBar para alertar usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$title\n$body")),
      );
    });
  }
}
