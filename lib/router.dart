import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/pages/admin/admin_produtosdisp_lista_pedidos.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/admin/admin_lista_pedidos.dart';
import 'package:padariavinhos/pages/admin/cadastro_acompanhamento_page.dart';
import 'package:padariavinhos/pages/conclusao_pedido.dart';
import 'package:padariavinhos/pages/fazer_pedido_page.dart';
import 'package:padariavinhos/pages/login_page.dart';
import 'package:padariavinhos/pages/menuinicial_page.dart';
import 'package:padariavinhos/pages/offline.dart';
import 'package:padariavinhos/pages/opcoes_page.dart';
import 'package:padariavinhos/pages/quem_somos_page.dart';
import 'package:padariavinhos/pages/signup_page.dart';
import 'package:padariavinhos/pages/splash_screen.dart';
import 'package:padariavinhos/pages/cadastro_produto_page.dart';
import 'package:padariavinhos/pages/admin/menu_admin.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/services/transitions.dart';
import 'package:padariavinhos/pages/meus_pedidos_page.dart';
import 'package:padariavinhos/pages/admin/admin_combo_page.dart';
import 'package:padariavinhos/pages/product_detalhe_page.dart';
import 'package:padariavinhos/pages/LGPD_page.dart';
import 'package:padariavinhos/widgets/imagem_produto.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/pages/admin/abertura_page.dart';

GoRouter createRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,

    redirect: (context, state) {
      final isLoggedIn = authNotifier.isAuthenticated;
      final isOnline = authNotifier.isOnline;
      final role = authNotifier.role;
      final location = state.matchedLocation;

      debugPrint('[Redirect] location: $location | role: $role | loggedIn: $isLoggedIn | splash: ${authNotifier.splashFinished}');

      if (location == '/splash') {
        if (!authNotifier.splashFinished) return null;

        if (isLoggedIn) {
          if (role == 'admin') return '/admin';
          return '/menu';
        }
        return '/login';
      }

      if (!isLoggedIn && !['/login', '/signup', '/lgpd'].contains(location)) {
        return '/login';
      }

      if (['/menu', '/pedido', '/orcamento'].contains(location) && !isOnline) {
        return '/offline';
      }

      return null;
    },

    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: const _RedirectToMenu(),
    ),

    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const SplashScreen(), state: state),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const MenuAdmin(), state: state),
      ),

      GoRoute(
        path: '/acomp',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const CadastroAcompanhamentoPage(), state: state),
      ),

      GoRoute(
        path: '/produto/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailPage(produtoId: id);
        },
      ),

      GoRoute(
        path: '/listaproduto',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: AdminProdutosPage(), state: state),
      ),

      GoRoute(
        path: '/lista',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: ListaPedidosPage(), state: state),
      ),

      GoRoute(
        path: '/signin',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: LoginPage(), state: state),
      ),

      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: SignUpPage(), state: state),
      ),
      GoRoute(
        path: '/lgpd',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const PDFScreen(), state: state),
      ),

      GoRoute(
        path: '/comboadmin',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: AdminCombosPage(), state: state),
      ),
      GoRoute(
        path: '/cadastro-produto',
        pageBuilder: (c, s) =>
            fadeTransitionPage(child: CadastroProdutoPage(), state: s),
      ),
      GoRoute(
        path: '/config-abertura',
        pageBuilder: (c, s) =>
            fadeTransitionPage(child: ConfigAberturaPage(), state: s),
      ),
      GoRoute(
        path: '/imagem-produto/:id',
        builder: (context, state) {
          final produto = state.extra as Produto;
          return ImagemProdutoPage(produto: produto);
        },
      ),
      GoRoute(
        path: '/offline',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const OfflinePage(), state: state),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const LoginPage(), state: state),
      ),

      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const SignUpPage(), state: state),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final hideNav = state.uri.path == '/menu';

          return Scaffold(
            body: child,
            bottomNavigationBar: hideNav
                ? null
                : BottomNavigationBar(
              currentIndex: _getIndexFromLocation(state.uri.path),
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                const paths = [
                  '/menu',
                  '/meuspedidos',
                  '/pedido',
                  '/opcoes',
                  '/conclusao-pedido'
                ];
                context.go(paths[index]);
              },
              items: [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.home), label: 'Menu'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.receipt), label: 'Meus Pedidos'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle), label: 'Pedido'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Opções'),
                BottomNavigationBarItem(
                  icon: Consumer<CarrinhoProvider>(
                    builder: (_, carrinho, __) {
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
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border:
                                  Border.all(color: Colors.white),
                                ),
                                child: const Icon(
                                  Icons.priority_high,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            )
                        ],
                      );
                    },
                  ),
                  label: 'Conclusão',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
              path: '/menu',
              pageBuilder: (c, s) =>
                  fadeTransitionPage(child: MenuInicial(), state: s)),
          GoRoute(
              path: '/meuspedidos',
              pageBuilder: (c, s) =>
                  fadeTransitionPage(child: MeuPedidoPage(), state: s)),
          GoRoute(
              path: '/pedido',
              pageBuilder: (c, s) =>
                  fadeTransitionPage(child: FazerPedidoPage(), state: s)),
          GoRoute(
              path: '/opcoes',
              pageBuilder: (c, s) =>
                  fadeTransitionPage(child: OpcoesPage(), state: s)),
          GoRoute(
              path: '/conclusao-pedido',
              pageBuilder: (c, s) =>
                  fadeTransitionPage(child: ConclusaoPedidoPage(), state: s)),
        ],
      ),
      GoRoute(
        path: '/quem-somos',
        pageBuilder: (c, s) => fadeTransitionPage(
          child: const QuemSomosPage(),
          state: s,
        ),
      ),
      GoRoute(
        path: '/cadastro-produto',
        pageBuilder: (c, s) =>
            fadeTransitionPage(child: CadastroProdutoPage(), state: s),
      ),
    ],
  );
}

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

class _RedirectToMenu extends StatefulWidget {
  const _RedirectToMenu({super.key});

  @override
  State<_RedirectToMenu> createState() => _RedirectToMenuState();
}

class _RedirectToMenuState extends State<_RedirectToMenu> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/menu');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}