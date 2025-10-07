// File: lib/services/notification_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// 🔹 Inicializa o serviço de notificações (local + handlers de mensagens)
  static Future<void> init(BuildContext context) async {
    await _initLocalNotifications(context);
    await _initMessageHandlers(context);
  }

  /// 🔹 Registra o token inicial do usuário (login/signup)
  static Future<void> initFCM(String uid) async {
    await getFcmToken(uid); // usa a função abaixo para salvar token

    // 🔹 Escuta mudanças no token e atualiza Firestore
    _fcm.onTokenRefresh.listen((newToken) async {
      await _saveTokenToFirestore(uid, newToken);
      print("♻️ FCM Token atualizado: $newToken");
    });
  }

  /// 🔹 Obtém e salva o token de forma profissional
  static Future<String?> getFcmToken(String uid) async {
    try {
      // Solicita permissão (iOS, Android 13+)
      final settings = await _fcm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print("⚠️ Permissão de notificações negada");
        return null;
      }

      // Obtém token atual
      final token = await _fcm.getToken();
      if (token == null) {
        print("❌ Não foi possível gerar FCM Token");
        return null;
      }

      // Salva no Firestore de forma única
      await _saveTokenToFirestore(uid, token);
      print("✅ FCM Token salvo: $token");

      return token;
    } catch (e) {
      print("❌ Erro ao obter FCM Token: $e");
      return null;
    }
  }

  /// 🔹 Inicializa notificações locais
  static Future<void> _initLocalNotifications(BuildContext context) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationClick(context, response.payload!);
        }
      },
    );
  }

  /// 🔹 Configura handlers para mensagens FCM
  static Future<void> _initMessageHandlers(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('pedidoId')) {
        _handleNotificationClick(context, message.data['pedidoId']);
      }
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage?.data.containsKey('pedidoId') ?? false) {
      _handleNotificationClick(context, initialMessage!.data['pedidoId']);
    }
  }

  /// 🔹 Salva token no Firestore
  static Future<void> _saveTokenToFirestore(String uid, String token) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({
      'fcmTokens': FieldValue.arrayUnion([token])
    }, SetOptions(merge: true));
  }

  /// 🔹 Remove token do Firestore (logout)
  static Future<void> removeToken(String uid, String token) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.update({
      'fcmTokens': FieldValue.arrayRemove([token])
    });
  }

  /// 🔹 Mostra notificação local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'pedidos_channel',
      'Pedidos',
      channelDescription: 'Notificações de pedidos',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['pedidoId'],
    );
  }

  /// 🔹 Lida com clique na notificação (admin -> lista, cliente -> pedido específico)
  static void _handleNotificationClick(BuildContext context, String pedidoId) {
    final auth = fb_auth.FirebaseAuth.instance.currentUser;
    if (auth == null) return;

    FirebaseFirestore.instance.collection('users').doc(auth.uid).get().then((doc) {
      final role = doc.data()?['role'] ?? 'cliente';

      if (role == 'admin') {
        context.go('/lista'); // Admin ListaPedidosPage
      } else {
        context.go('/meuspedidos', extra: pedidoId); // Cliente MeuPedidoPage
      }
    });
  }
}
