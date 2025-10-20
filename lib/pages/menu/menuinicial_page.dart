import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/menu/menu_button.dart';
import 'package:padariavinhos/widgets/auth_panel.dart';
import 'package:padariavinhos/widgets/custom_popup.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/notifiers/pedido_listener_notifier.dart';
import 'package:padariavinhos/services/pedido_listener_service.dart';
import 'package:go_router/go_router.dart';


// @override
// void initState() {
//   super.initState();
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     CustomDialog.showInfo(
//       context,
//       title: "Aviso Especial",
//       message: "Hoje tem frango na Padaria!",
//       color: Colors.red,
//     );
//   });
// }

/// Página inicial com monitoramento de pedidos e menu principal
class MenuInicial extends StatelessWidget {
  const MenuInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não logado.')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => PedidoListenerNotifier(PedidoListenerService(), user.uid),
      child: const _MenuInicialView(),
    );
  }
}

class _MenuInicialView extends StatefulWidget {
  const _MenuInicialView();

  @override
  State<_MenuInicialView> createState() => _MenuInicialViewState();
}

class _MenuInicialViewState extends State<_MenuInicialView> {
  bool _mostrouAviso = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pedidoNotifier = context.watch<PedidoListenerNotifier>();

    if (pedidoNotifier.temAtualizacao && !_mostrouAviso) {
      _mostrouAviso = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomDialog.showInfo(
          context,
          title: "Atualização de Pedido",
          message: "Um dos seus pedidos mudou de status!",
          color: Colors.green,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red, Colors.black, Colors.black, Colors.green],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(screenHeight),
                  const SizedBox(height: 40),

                  buildMenuBotao(
                    context,
                    'Faça seu pedido',
                    Icons.shopping_cart,
                    Colors.green,
                    '/pedido',
                    largura: screenWidth,
                  ),
                  buildMenuBotao(
                    context,
                    'Veja seus pedidos',
                    Icons.receipt_long,
                    Colors.red,
                    null,
                    largura: screenWidth,
                  ),
                  buildMenuBotao(
                    context,
                    'Sua Conta',
                    Icons.person,
                    Colors.green,
                    '/opcoes',
                    largura: screenWidth,
                  ),
                  buildMenuBotao(
                    context,
                    'Quem Somos',
                    Icons.info,
                    Colors.red,
                    '/quem-somos',
                    largura: screenWidth,
                  ),
                  buildMenuBotao(
                    context,
                    'SAIR',
                    Icons.logout,
                    Colors.grey[850]!,
                    null,
                    isLogout: true,
                    largura: screenWidth,
                  ),
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

  Widget _buildLogo(double screenHeight) {
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
