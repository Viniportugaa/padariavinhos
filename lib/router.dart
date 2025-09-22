import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/pages/admin/admin_produtosdisp_lista_pedidos.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/admin/admin_lista_pedidos.dart';
import 'package:padariavinhos/pages/admin/cadastro_acompanhamento_page.dart';
import 'package:padariavinhos/pages/conclusao_pedido/conclusao_pedido_page.dart';
import 'package:padariavinhos/pages/fazer_pedido/fazer_pedido_page.dart';
import 'package:padariavinhos/pages/login_page.dart';
import 'package:padariavinhos/pages/menuinicial_page.dart';
import 'package:padariavinhos/pages/offline.dart';
import 'package:padariavinhos/pages/opcoes_page.dart';
import 'package:padariavinhos/pages/quem_somos_page.dart';
import 'package:padariavinhos/pages/signup_page.dart';
import 'package:padariavinhos/pages/splash_screen.dart';
import 'package:padariavinhos/pages/admin/cadastro_produto_page.dart';
import 'package:padariavinhos/pages/admin/menu_admin.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/helpers/transitions.dart';
import 'package:padariavinhos/pages/meus_pedidos_page.dart';
import 'package:padariavinhos/pages/product_detalhe_page.dart';
import 'package:padariavinhos/pages/LGPD_page.dart';
import 'package:padariavinhos/widgets/imagem_produto.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/pages/admin/abertura_page.dart';
import 'package:padariavinhos/pages/admin/admin_banner_page.dart';
import 'package:padariavinhos/pages/admin/admin_cria_categoria.dart';
import 'package:padariavinhos/pages/admin/relatorio_page.dart';
import 'package:padariavinhos/pages/admin/relatorio_cliente.dart';

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
        path: '/relatorio-clientes',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: RelatorioClientesPage(), state: state),
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
        path: '/relatorio',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const RelatorioPage(), state: state),
      ),
      GoRoute(
        path: '/banneradmin',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: AdminBannersPage(), state: state),
      ),
      GoRoute(
        path: '/categoriadmin',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: CriarCategoriaPage(), state: state),
      ),
      GoRoute(
        path: '/lgpd',
        pageBuilder: (context, state) =>
            fadeTransitionPage(child: const PDFScreen(), state: state),
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
      ShellRoute(
        builder: (context, state, child) {
          final hideNav = state.uri.path == '/menu';
          final currentIndex = _getIndexFromLocation(state.uri.path);
          final isPedidoPage = state.uri.path == '/pedido';

          return Scaffold(
            body: child,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton:(state.uri.path == '/menu') ? null : GestureDetector(
              onTap: () => context.go('/pedido'),
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: isPedidoPage ? Colors.red : Colors.grey[400],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(
                  Icons.add_circle,
                  size: 36,
                  color: isPedidoPage ? Colors.white : Colors.black54,
                ),
              ),
            ),
            bottomNavigationBar: hideNav
                ? null
                : BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, Icons.home, '/menu', currentIndex == 0),
                    _buildNavItem(context, Icons.receipt, '/meuspedidos', currentIndex == 1),
                    SizedBox(width: 70), // Espaço para o botão central
                    _buildNavItem(context, Icons.person, '/opcoes', currentIndex == 3),
                    Consumer<CarrinhoProvider>(
                      builder: (_, carrinho, __) {
                        final temItens = carrinho.itens.isNotEmpty;
                        return _buildNavItem(
                          context,
                          Icons.shopping_cart,
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
          );
        },
        routes: [
          GoRoute(
            path: '/menu',
            pageBuilder: (c, s) => fadeTransitionPage(child: MenuInicial(), state: s),
          ),
          GoRoute(
            path: '/meuspedidos',
            pageBuilder: (c, s) => fadeTransitionPage(child: MeuPedidoPage(), state: s),
          ),
          GoRoute(
            path: '/pedido',
            pageBuilder: (c, s) => fadeTransitionPage(child: FazerPedidoPage(), state: s),
          ),
          GoRoute(
            path: '/opcoes',
            pageBuilder: (c, s) => fadeTransitionPage(child: OpcoesPage(), state: s),
          ),
          GoRoute(
            path: '/conclusao-pedido',
            pageBuilder: (c, s) => fadeTransitionPage(child: ConclusaoPedidoPage(), state: s),
          ),
        ],
      )

    ],
  );
}

Widget _buildNavItem(BuildContext context, IconData icon, String path, bool selected, {String? label, bool badge = false}) {
  return InkWell(
    onTap: () => context.go(path),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: label == null
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: selected ? Colors.red : Colors.grey),
            if (badge)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Icon(
                    Icons.priority_high,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              )
          ],
        ),
        if (label != null)
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.red : Colors.grey,
              fontSize: 12,
            ),
          ),
      ],
    ),
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