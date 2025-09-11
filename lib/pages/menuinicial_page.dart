import 'dart:ui';
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      floatingActionButton: null,
      bottomNavigationBar: null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // verde escuro
              Colors.black87,
              Colors.black87,
              Color(0xFFD32F2F), // vermelho escuro
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
                  _buildGlassBotao(context, 'Faça seu pedido', Colors.green, '/pedido', largura: screenWidth),
                  _buildGlassBotao(context, 'Veja seus pedidos', Colors.red, '/meuspedidos', largura: screenWidth),
                  _buildGlassBotao(context, 'Sua Conta', Colors.green, '/opcoes', largura: screenWidth),
                  _buildGlassBotao(context, 'Quem Somos', Colors.red, '/quem-somos', largura: screenWidth, pequeno: true),
                  _buildGlassBotao(context, 'SAIR', Colors.grey[850]!, null, isLogout: true, largura: screenWidth),
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

  Widget _buildGlassBotao(
      BuildContext context,
      String texto,
      Color cor,
      String? rota, {
        bool pequeno = false,
        bool isLogout = false,
        required double largura,
      }) {
    final buttonWidth = pequeno ? largura * 0.5 : largura * 0.8;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: () async {
          if (isLogout) {
            _confirmarLogout(context);
          } else if (rota != null) {
            context.push(rota);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: buttonWidth,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
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

              // Remove FCM token
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final fcmToken = await FirebaseMessaging.instance.getToken();
                if (fcmToken != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('tokens')
                      .doc(fcmToken)
                      .delete()
                      .catchError((e) => print('Erro ao remover token FCM: $e'));
                }
                // Unsubscribe de tópicos
                List<String> topicos = ['promocoes', 'novidades']; // adicione seus tópicos aqui
                for (var topic in topicos) {
                  await FirebaseMessaging.instance
                      .unsubscribeFromTopic(topic)
                      .catchError((e) => print('Erro ao desinscrever do tópico $topic: $e'));
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
