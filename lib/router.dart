import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/pages/admin/admin_produtosdisp_lista_pedidos.dart';
import 'package:padariavinhos/pages/local/local_splash_screen.dart';
import 'package:padariavinhos/pages/local/painel_balcao_page.dart';
import 'package:padariavinhos/pages/local/fazer_pedido_local_page.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/admin/admin_lista_pedidos.dart';
import 'package:padariavinhos/pages/admin/cadastro_acompanhamento_page.dart';
import 'package:padariavinhos/pages/conclusao_pedido/conclusao_pedido_page.dart';
import 'package:padariavinhos/pages/fazer_pedido/fazer_pedido_page.dart';
import 'package:padariavinhos/pages/login_page.dart';
import 'package:padariavinhos/pages/menu/menuinicial_page.dart';
import 'package:padariavinhos/pages/offline.dart';
import 'package:padariavinhos/pages/opcoes_page.dart';
import 'package:padariavinhos/pages/quem_somos_page.dart';
import 'package:padariavinhos/pages/signup/signup_page.dart';
import 'package:padariavinhos/pages/splash_screen.dart';
import 'package:padariavinhos/pages/admin/cadastro_produto_page.dart';
import 'package:padariavinhos/pages/admin/menu_admin.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/helpers/transitions.dart';
import 'package:padariavinhos/pages/meus_pedidos_page.dart';
import 'package:padariavinhos/pages/LGPD_page.dart';
import 'package:padariavinhos/widgets/imagem_produto.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/pages/admin/abertura_page.dart';
import 'package:padariavinhos/pages/admin/admin_banner_page.dart';
import 'package:padariavinhos/pages/admin/admin_cria_categoria.dart';
import 'package:padariavinhos/pages/admin/relatorio_page.dart';
import 'package:padariavinhos/pages/admin/relatorio_cliente.dart';
import 'package:padariavinhos/custom_shell.dart';
import 'package:padariavinhos/pages/admin/cupons_admin_page.dart';
import 'package:padariavinhos/pages/local/local_splash_screen.dart';

GoRouter createRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,

    redirect: (context, state) {
      final isLoggedIn = authNotifier.isAuthenticated;
      final isOnline = authNotifier.isOnline;
      final role = authNotifier.role;
      final location = state.matchedLocation;
      final splashDone = authNotifier.splashFinished;

      debugPrint(
          '[Redirect] loc=$location | role=$role | loggedIn=$isLoggedIn | splash=$splashDone');

      // 1️⃣ Espera o splash terminar
      if (!splashDone) return null;

      // 2️⃣ Se não está logado → login
      if (!isLoggedIn) {
        if (!['/login', '/signup', '/lgpd', '/offline'].contains(location)) {
          return '/login';
        }
        return null;
      }

      // 3️⃣ Espera role carregar
      if (role == null || role.isEmpty) {
        return null;
      }

      // 4️⃣ Pós-login ou splash: redireciona conforme role
      if (location == '/splash' || location == '/login' || location == '/signup') {
        if (role == 'admin') return '/admin';
        if (role == 'cliente_local') return '/local-splash';
        return '/menu';
      }

      // 5️⃣ Se admin está em /menu, manda pro /admin
      if (role == 'admin' && location.startsWith('/menu')) {
        return '/admin';
      }

      // 6️⃣ Se cliente tenta acessar admin, bloqueia
      if (role != 'admin' && location.startsWith('/admin')) {
        return '/menu';
      }

      // 7️⃣ Se estiver offline e rota requer internet
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
            scaleTransitionPage(child: const SplashScreen(), state: state),
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
        path: '/imagem-produto',
        pageBuilder: (context, state) {
          final produto = state.extra as Produto;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ImagemProdutoPage(produto: produto),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),

      GoRoute(
        path: '/listaproduto',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: AdminProdutosPage(), state: state),
      ),

      GoRoute(
        path: '/cupomadmin',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: CuponsAdminPage(), state: state),
      ),

      GoRoute(
        path: '/local-splash',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: LocalSplashScreen(), state: state),
      ),

  GoRoute(
        path: '/relatorio-clientes',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: RelatorioClientesPage(), state: state),
      ),

      GoRoute(
        path: '/local2',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: FazerPedidoLocalPage(), state: state),
      ),

      GoRoute(
        path: '/local',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: PainelBalcaoPage(), state: state),
      ),

      GoRoute(
        path: '/lista',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: ListaPedidosPage(), state: state),
      ),

      GoRoute(
        path: '/signin',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: LoginPage(), state: state),
      ),

      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: SignUpPage(), state: state),
      ),
      GoRoute(
        path: '/relatorio',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: const RelatorioPage(), state: state),
      ),
      GoRoute(
        path: '/banneradmin',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: AdminBannersPage(), state: state),
      ),
      GoRoute(
        path: '/categoriadmin',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: CriarCategoriaPage(), state: state),
      ),
      GoRoute(
        path: '/lgpd',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: const PoliticaPrivacidadePage(), state: state),
      ),
      GoRoute(
        path: '/cadastro-produto',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: CadastroProdutoPage(), state: s),
      ),
      GoRoute(
        path: '/config-abertura',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: ConfigAberturaPage(), state: s),
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
            scaleTransitionPage(child: const OfflinePage(), state: state),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: const LoginPage(), state: state),
      ),

      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            scaleTransitionPage(child: const SignUpPage(), state: state),
      ),
      GoRoute(
        path: '/quem-somos',
        pageBuilder: (c, s) => scaleTransitionPage(
          child: const QuemSomosPage(),
          state: s,
        ),
      ),
      GoRoute(
        path: '/cadastro-produto',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: CadastroProdutoPage(), state: s),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            CustomShell(child: child, state: state),
        routes: [
          GoRoute(
            path: '/menu',
            pageBuilder: (c, s) =>
                slideFadeTransitionPage(child: MenuInicial(), state: s),
          ),
          GoRoute(
            path: '/meuspedidos',
            pageBuilder: (c, s) =>
                slideFadeTransitionPage(child: MeuPedidoPage(), state: s),
          ),
          GoRoute(
            path: '/pedido',
            pageBuilder: (c, s) =>
                slideFadeTransitionPage(child: FazerPedidoPage(), state: s),
          ),
          GoRoute(
            path: '/opcoes',
            pageBuilder: (c, s) =>
                slideFadeTransitionPage(child: OpcoesPage(), state: s),
          ),
          GoRoute(
            path: '/conclusao-pedido',
            pageBuilder: (c, s) =>
                slideFadeTransitionPage(child: ConclusaoPedidoPage(), state: s),
          ),
        ],
      ),
    ],
  );
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