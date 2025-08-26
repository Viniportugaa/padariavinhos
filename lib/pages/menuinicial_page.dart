import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:padariavinhos/widgets/auth_panel.dart';

import 'package:padariavinhos/services/auth_notifier.dart';

class MenuInicial extends StatelessWidget {
  const MenuInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green,
              Colors.black,
              Colors.black,
              Colors.red,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Image.asset(
                      'assets/LogoPadariaVinhosBranco.png',
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.25,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBotao(context, 'Faça seu pedido', Colors.green, '/pedido'),
                  _buildBotao(context, 'Veja seus pedidos', Colors.red, '/meuspedidos'),
                  _buildBotao(context, 'Sua Conta', Colors.green, '/opcoes'),
                  _buildBotao(context, 'Quem Somos', Colors.red, '/quem-somos', pequeno: true),
                  _buildBotao(context, 'SAIR', Colors.grey[850]!, null, isLogout: true),

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
  Widget _buildBotao(
      BuildContext context,
      String texto,
      Color cor,
      String? rota, {
        bool pequeno = false,
        bool isLogout = false,
      }) {
    final largura = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: pequeno ? largura * 0.5 : largura * 0.8,
        child: ElevatedButton(
          onPressed: () async {
            if (isLogout) {
              _confirmarLogout(context);
            } else if (rota != null)  {
              context.push(rota);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(texto, style: const TextStyle(fontSize: 16)),
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
              await auth.logout(); // notificará GoRouter se estiver integrado
              dialogContext.pop(); // fecha o diálogo
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  context.go('/splash'); // redireciona
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

