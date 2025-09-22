import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:padariavinhos/widgets/auth_panel.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';

Widget buildMenuBotao(
    BuildContext context,
    String texto,
    IconData icone,
    Color cor,
    String? rota, {
      bool isLogout = false,
      required double largura,
    }) {
  final buttonWidth = largura * 0.85;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: GestureDetector(
      onTap: () async {
        if (isLogout) {
          confirmarLogout(context);
        } else if (rota != null) {
          context.push(rota);
        }
      },
      child: Container(
        width: buttonWidth,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLogout
                ? [Colors.grey[700]!, Colors.grey[800]!]
                : [cor.withOpacity(0.9), cor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void confirmarLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Confirmação'),
      content: const Text('Tem certeza que deseja sair?'),
      actions: [
        TextButton(
          onPressed: () => dialogContext.pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            final auth = Provider.of<AuthNotifier>(context, listen: false);

            // Remove FCM token do array fcmTokens
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'fcmTokens': FieldValue.arrayRemove([fcmToken])
                }).catchError((e) =>
                    print('Erro ao remover token FCM: $e'));
              }

              if (!kIsWeb) {
                // Unsubscribe de tópicos apenas em mobile
                List<String> topicos = ['promocoes', 'novidades'];
                for (var topic in topicos) {
                  await FirebaseMessaging.instance
                      .unsubscribeFromTopic(topic)
                      .catchError((e) =>
                      print('Erro ao desinscrever do tópico $topic: $e'));
                }
              } else {
                print(
                    '⚠️ unsubscribeFromTopic não é suportado no Web. Gerencie via Admin SDK.');
              }
            }

            // Logout do app
            await auth.logout();

            dialogContext.pop();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                context.go('/splash');
              }
            });
          },
          child: const Text('Sair'),
        ),
      ],
    ),
  );
}

