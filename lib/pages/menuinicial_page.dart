import 'package:flutter/material.dart';
import 'package:padariavinhos/widgets/menu_button.dart';
import 'package:padariavinhos/widgets/auth_panel.dart';

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
                  buildMenuBotao(context, 'Faça seu pedido', Icons.shopping_cart, Colors.green, '/pedido', largura: screenWidth),
                  buildMenuBotao(context, 'Veja seus pedidos', Icons.receipt_long, Colors.red, '/meuspedidos', largura: screenWidth),
                  buildMenuBotao(context, 'Sua Conta', Icons.person, Colors.green, '/opcoes', largura: screenWidth),
                  buildMenuBotao(context, 'Quem Somos', Icons.info, Colors.red, '/quem-somos', largura: screenWidth),
                  buildMenuBotao(context, 'SAIR', Icons.logout, Colors.grey[850]!, null, isLogout: true, largura: screenWidth),
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
}
