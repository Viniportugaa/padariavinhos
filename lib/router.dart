import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/pages/conclusao_pedido.dart';
import 'package:padariavinhos/widgets/auth_check.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';

// Importa suas páginas
import 'services/transitions.dart';
import 'services/auth_notifier.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/opcoes_page.dart';
import 'pages/fazer_pedido_page.dart';
import 'pages/fazer_orcamento_page.dart';
import 'pages/sua_conta_page.dart';
import 'pages/quem_somos_page.dart';
import 'pages/cadastro_produto_page.dart';
import 'pages/menuinicial_page.dart';

// 'final authNotifier = AuthNotifier();

// final GoRouter router = GoRouter(
//   initialLocation: '/',
//   refreshListenable: authNotifier,
//
//   redirect: (context, state) {
//     final user = FirebaseAuth.instance.currentUser;
//     final isLoggedIn = user != null;
//     final isOnSplash = state.matchedLocation == '/';
//     final isAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
//
//     if (isOnSplash) {
//       // Só sai da splash se o tempo passou
//       if (!authNotifier.splashFinished) return null;
//       return isLoggedIn ? '/menu' : '/login';
//     }
//
//     if (!isLoggedIn && !isAuthPage) return '/login';
//     if (isLoggedIn && isAuthPage) return '/menu';
//     return null;
//   },
//
//   errorPageBuilder: (context, state) {
//     return MaterialPage(
//       key: state.pageKey,
//       child: _RedirectToMenu(),
//     );
//   },
//
//
//   routes: [
//     GoRoute(
//       path: '/',
//       pageBuilder: (context, state) =>
//           fadeTransitionPage(child: const SplashScreen(), state: state),
//     ),
//
//     GoRoute(
//       path: '/login',
//       pageBuilder: (context, state) =>
//         fadeTransitionPage(child: const LoginPage(), state: state),
//     ),
//     GoRoute(
//       path: '/signup',
//       pageBuilder: (context, state) =>
//           fadeTransitionPage(child: const SignUpPage(), state: state),
//     ),
//
//     GoRoute(
//       path: '/opcoes',
//       pageBuilder: (context, state) =>
//           fadeTransitionPage(child: OpcoesPage(), state: state),
//     ),
//     GoRoute(
//       path: '/pedido',
//       pageBuilder: (context, state) =>
//           fadeTransitionPage(child: FazerPedidoPage(), state: state),
//     ),
//
//     GoRoute(
//       path: '/orcamento',
//       pageBuilder: (context, state) =>
//           fadeTransitionPage(child: FazerOrcamentoPage(), state: state),
//     ),
//     GoRoute(
//       path: '/conta',
//       pageBuilder: (context, state) =>
//           fadeTransitionPage(child: SuaContaPage(), state: state),
//     ),
//     GoRoute(path: '/quem-somos', builder: (context, state) => const QuemSomosPage()),
//     GoRoute(path: '/cadastro-produto', builder: (context, state) => const CadastroProdutoPage()),
//     GoRoute(
//       path: '/menu',
//       pageBuilder: (context, state) =>
//         fadeTransitionPage(child: MenuInicial(), state: state),
//     ),
//   ],
// );

int _getIndexFromLocation(String path) {
  if (path.startsWith('/menu')) return 0;
  if (path.startsWith('/orcamento')) return 1;
  if (path.startsWith('/pedido')) return 2;
  if (path.startsWith('/conta')) return 3;
  if (path.startsWith('/conclusao-pedido')) return 4;
  return 0;
  }

final GoRouter router = GoRouter(
  initialLocation: '/',
  // 'refreshListenable: authNotifier,

  // lógica de autenticação existente
  // redirect: (context, state) {
  //   final user = FirebaseAuth.instance.currentUser;
  //   final isLoggedIn = user != null;
  //   final isOnSplash = state.matchedLocation == '/';
  //   final isAuthPage = ['/login', '/signup'].contains(state.matchedLocation);
  //
  //   if (isOnSplash) {
  //     //'if (!authNotifier.splashFinished) return null;
  //     return isLoggedIn ? '/menu' : '/login';
  //   }
  //
  //   if (!isLoggedIn && !isAuthPage) return '/login';
  //   if (isLoggedIn && isAuthPage) return '/menu';
  //   return null;
  // },

  // captura qualquer rota inválida e redireciona ao /menu
  errorPageBuilder: (context, state) {
    return MaterialPage(
      key: state.pageKey,
      child: _RedirectToMenu(),
    );
  },

  routes: [
    // rotas sem BottomNav
    GoRoute(
      path: '/',
      pageBuilder: (c, s) => fadeTransitionPage(child: AuthCheck(), state: s),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (c, s) => fadeTransitionPage(child: const LoginPage(), state: s),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (c, s) => fadeTransitionPage(child: const SignUpPage(), state: s),
    ),
    GoRoute(
      path: '/opcoes',
      pageBuilder: (c, s) => fadeTransitionPage(child: OpcoesPage(), state: s),
    ),

    // ShellRoute agrupa as páginas que usam BottomNavigationBar
    ShellRoute(

      builder: (context, state, child) {
        final shouldShowBottomNav = state.uri.path != '/menu';
        return Scaffold(
          body: child,
          bottomNavigationBar: shouldShowBottomNav
              ?BottomNavigationBar(
            currentIndex: _getIndexFromLocation(state.uri.path),
            selectedItemColor: Colors.red,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              const routes = ['/menu', '/orcamento', '/pedido', '/conta', '/conclusao-pedido'];
              final targetRoute = routes[index];
              if (state.uri.path != targetRoute) {
                context.go(targetRoute);
              }
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orçamento'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Pedido'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
              BottomNavigationBarItem(
                icon: Consumer<CarrinhoProvider>(
                  builder: (context, carrinho, _) {
                    final temItens = carrinho.itens.isNotEmpty;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart),
                        if (temItens)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.priority_high,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                label: 'Conclusão',
              ),

            ],
          )
          : null, // 👈 oculta se estiver na rota /men
        );
      },
      routes: [
        GoRoute(
          path: '/menu',
          pageBuilder: (c, s) =>
              fadeTransitionPage(child: MenuInicial(), state: s),
        ),
        GoRoute(
          path: '/orcamento',
          pageBuilder: (c, s) =>
              fadeTransitionPage(child: FazerOrcamentoPage(), state: s),
        ),
        GoRoute(
          path: '/pedido',
          pageBuilder: (c, s) =>
              fadeTransitionPage(child: FazerPedidoPage(), state: s),
        ),
        GoRoute(
          path: '/conta',
          pageBuilder: (c, s) =>
              fadeTransitionPage(child: SuaContaPage(), state: s),
        ),
        GoRoute(
          path: '/conclusao-pedido',
          pageBuilder: (c, s) => fadeTransitionPage(child: ConclusaoPedidoPage(), state: s),
        ),
      ],
    ),

    // rotas auxiliares
    GoRoute(
      path: '/quem-somos',
      pageBuilder: (c, s) => fadeTransitionPage(child: const QuemSomosPage(), state: s),
    ),
    GoRoute(
      path: '/cadastro-produto',
      pageBuilder: (c, s) =>
          fadeTransitionPage(child: CadastroProdutoPage(), state: s),
    ),
  ],
);


class _RedirectToMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.microtask(() => context.go('/menu'));

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


