import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';

class CustomShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const CustomShell({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final hideNav = state.uri.path == '/menu';
    final currentIndex = _getIndexFromLocation(state.uri.path);
    final isPedidoPage = state.uri.path == '/pedido';

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[50],
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔹 Botão central (pedido)
      floatingActionButton: hideNav
          ? null
          : GestureDetector(
        onTap: () => context.go('/pedido'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPedidoPage
                  ? [Colors.redAccent, Colors.red]
                  : [Colors.grey.shade400, Colors.grey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_circle,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),

      bottomNavigationBar: hideNav
          ? null
          : ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 12,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    context,
                    Icons.home_rounded,
                    '/menu',
                    currentIndex == 0,
                  ),
                  _buildNavItem(
                    context,
                    Icons.receipt_long_rounded,
                    '/meuspedidos',
                    currentIndex == 1,
                  ),
                  const SizedBox(width: 60),
                  _buildNavItem(
                    context,
                    Icons.person_rounded,
                    '/opcoes',
                    currentIndex == 3,
                  ),
                  Consumer<CarrinhoProvider>(
                    builder: (_, carrinho, __) {
                      final temItens = carrinho.itens.isNotEmpty;
                      return _buildNavItem(
                        context,
                        Icons.shopping_cart_rounded,
                        '/conclusao-pedido',
                        currentIndex == 4,
                        badge: temItens,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Item da Bottom Nav (somente ícone)
  Widget _buildNavItem(
      BuildContext context,
      IconData icon,
      String path,
      bool selected, {
        bool badge = false,
      }) {
    final color = selected ? Colors.redAccent : Colors.grey;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go(path),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 28),
            if (badge)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Índice de rota
  int _getIndexFromLocation(String path) {
    switch (path) {
      case '/menu':
        return 0;
      case '/meuspedidos':
        return 1;
      case '/pedido':
        return 2;
      case '/opcoes':
        return 3;
      case '/conclusao-pedido':
        return 4;
      default:
        return 0;
    }
  }
}
