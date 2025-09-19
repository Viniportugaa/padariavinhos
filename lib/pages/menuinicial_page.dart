import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:padariavinhos/widgets/auth_panel.dart';
import 'package:padariavinhos/services/auth_notifier.dart';

class MenuInicial extends StatelessWidget {
  const MenuInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      floatingActionButton: null,
      bottomNavigationBar: null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red,
              Colors.black,
              Colors.black,
              Colors.green,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(context, screenHeight),
                  const SizedBox(height: 40),
                  _buildMenuBotao(context, 'Faça seu pedido', Icons.shopping_cart, Colors.green, '/pedido', largura: screenWidth),
                  _buildMenuBotao(context, 'Veja seus pedidos', Icons.receipt_long, Colors.red, '/meuspedidos', largura: screenWidth),
                  _buildMenuBotao(context, 'Sua Conta', Icons.person, Colors.green, '/opcoes', largura: screenWidth),
                  _buildMenuBotao(context, 'Quem Somos', Icons.info, Colors.red, '/quem-somos', largura: screenWidth),
                  _buildMenuBotao(context, 'SAIR', Icons.logout, Colors.grey[850]!, null, isLogout: true, largura: screenWidth),
                  const SizedBox(height: 40),
                  const AuthStatusPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        height: screenHeight * 0.25,
        child: Image.asset(
          'assets/LogoPadariaVinhosBranco.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildMenuBotao(
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
            _confirmarLogout(context);
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


  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text('Confirmação'),
            content: const Text('Tem certeza que deseja sair?'),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final auth = Provider.of<AuthNotifier>(
                      context, listen: false);

                  // Remove FCM token
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final fcmToken = await FirebaseMessaging.instance
                        .getToken();
                    if (fcmToken != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('tokens')
                          .doc(fcmToken)
                          .delete()
                          .catchError((e) =>
                          print('Erro ao remover token FCM: $e'));
                    }
                    if (!kIsWeb) {
                      // Unsubscribe de tópicos apenas em mobile
                      List<String> topicos = [
                        'promocoes',
                        'novidades'
                      ]; // adicione seus tópicos
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
}
