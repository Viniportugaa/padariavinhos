import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Verifica e solicita permissão para notificações
  static Future<void> checkAndRequestPermission(BuildContext context) async {
    // 🔹 WEB não pede permissão da mesma forma que iOS/Android
    if (kIsWeb) {
      final token = await _fcm.getToken();
      debugPrint('🔔 Web FCM Token: $token');
      return;
    }

    final settings = await _fcm.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // usuário já negou antes -> mostrar alerta explicativo
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notificações Desativadas'),
          content: const Text(
            'Você desativou as notificações. '
                'Ative manualmente nas configurações do dispositivo para receber promoções e pedidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      // Primeiro pedido de permissão
      final allow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permitir Notificações'),
          content: const Text(
              'Gostaria de receber notificações de pedidos e promoções?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        ),
      );

      if (allow == true) {
        final newSettings = await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        debugPrint('🔔 Permissão concedida: ${newSettings.authorizationStatus}');
      }
    }

    // 🔹 Obter token atualizado sempre
    final token = await _fcm.getToken();
    debugPrint('🔔 FCM Token: $token');
  }
}
