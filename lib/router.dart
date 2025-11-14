import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:padariavinhos/pages/admin/admin_produtosdisp_lista_pedidos.dart';
import 'package:padariavinhos/pages/local/local_splash_screen.dart';
import 'package:padariavinhos/pages/local/painel_balcao_page.dart';
import 'package:padariavinhos/pages/local/fazer_pedido_local_page.dart';
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

GoRouter createRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,

    redirect: (context, state) {
      final isLogged = authNotifier.isAuthenticated;
      final isOnline = authNotifier.isOnline;
      final role = authNotifier.role;
      final splashDone = authNotifier.splashFinished;
      final loc = state.matchedLocation;

      debugPrint('[Router] loc=$loc role=$role');

      // SPLASH ainda carregando
      if (!splashDone) return null;

      // NÃO logado → só permite login/signup/lgpd/offline
      if (!isLogged) {
        final publico = [
      '/login',
      '/signup',
      '/lgpd',
      '/offline',
      ];
      if (publico.any((e) => loc.startsWith(e))) return null;
      return '/login';
      }

      // COM login — ROLE obrigatório
      if (role == null || role.isEmpty) return null;

      // pós login → define home por role
      if (loc.startsWith('/splash') ||
      loc.startsWith('/login') ||
      loc.startsWith('/signup')) {
      if (role == 'admin') return '/admin';
      if (role == 'cliente_local') return '/local-splash';
      return '/menu';
      }

      // bloqueio de admin
      if (role == 'admin' && loc.startsWith('/menu')) return '/admin';
      if (role != 'admin' && loc.startsWith('/admin')) return '/menu';

      // offline bloqueia páginas críticas
      if (!isOnline &&
      ['/menu', '/pedido', '/orcamento'].any(loc.startsWith)) {
      return '/offline';
      }

      return null;
    },

    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: const _RedirectToMenu(),
    ),

    routes: [

      // --------------------------
      // PÚBLICAS
      // --------------------------
      GoRoute(
        path: '/splash',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: const SplashScreen(), state: s),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: const LoginPage(), state: s),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: const SignUpPage(), state: s),
      ),
      GoRoute(
        path: '/lgpd',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: const PoliticaPrivacidadePage(), state: s),
      ),
      GoRoute(
        path: '/offline',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: const OfflinePage(), state: s),
      ),

      // --------------------------
      // ADMIN
      // --------------------------
      GoRoute(
        path: '/admin',
        pageBuilder: (c, s) =>
            fadeTransitionPage(child: const MenuAdmin(), state: s),
      ),
      GoRoute(
        path: '/acomp',
        pageBuilder: (c, s) =>
            fadeTransitionPage(child: const CadastroAcompanhamentoPage(), state: s),
      ),
      GoRoute(
        path: '/listaproduto',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: AdminProdutosPage(), state: s),
      ),
      GoRoute(
        path: '/cupomadmin',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: CuponsAdminPage(), state: s),
      ),
      GoRoute(
        path: '/relatorio-clientes',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: RelatorioClientesPage(), state: s),
      ),
      GoRoute(
        path: '/relatorio',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: const RelatorioPage(), state: s),
      ),
      GoRoute(
        path: '/banneradmin',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: AdminBannersPage(), state: s),
      ),
      GoRoute(
        path: '/categoriadmin',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: CriarCategoriaPage(), state: s),
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

      // --------------------------
      // LOCAL (mesa / balcão)
      // --------------------------
      GoRoute(
        path: '/local-splash',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: LocalSplashScreen(), state: s),
      ),
      GoRoute(
        path: '/local2',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: FazerPedidoLocalPage(), state: s),
      ),
      GoRoute(
        path: '/local',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: PainelBalcaoPage(), state: s),
      ),

      // --------------------------
      // LISTA DE PEDIDOS (admin)
      // --------------------------
      GoRoute(
        path: '/lista',
        pageBuilder: (c, s) =>
            scaleTransitionPage(child: ListaPedidosPage(), state: s),
      ),

      // --------------------------
      // IMAGEM DO PRODUTO
      // --------------------------
      GoRoute(
        path: '/imagem-produto',
        pageBuilder: (context, state) {
          final produto = state.extra as Produto;
          return fadeTransitionPage(
            child: ImagemProdutoPage(produto: produto),
            state: state,
          );
        },
      ),

      // --------------------------
      // ÁREA DO CLIENTE (SHELL)
      // --------------------------
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
      if (mounted) context.go('/menu');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
