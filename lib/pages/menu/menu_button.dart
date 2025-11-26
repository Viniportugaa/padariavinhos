import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:padariavinhos/services/notification_service.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/notifiers/pedido_listener_notifier.dart';
import 'package:padariavinhos/widgets/custom_popup.dart';

/// -----------------------------------------------------------
/// 🌟 Botão de menu com integração de atualização de pedidos
/// -----------------------------------------------------------
Widget buildMenuBotao(
    BuildContext context,
    String texto,
    IconData icone,
    Color cor,
    String? rota, {
      bool isLogout = false,
      required double largura,
    }) {
  final buttonWidth = largura * 0.85;
  final pedidoNotifier = context.read<PedidoListenerNotifier?>();
  final temAtualizacao =
      texto == 'Veja seus pedidos' && pedidoNotifier?.temAtualizacao == true;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6), // menos espaçamento
    child: GestureDetector(
      onTap: () async {
        if (isLogout) {
          // 🔒 Chama diálogo que chama o AuthNotifier.logout()
          confirmarLogout(context);
          return;
        }

        if (rota != null) {
          context.push(rota);
          return;
        }

        if (texto == 'Veja seus pedidos') {
          if (pedidoNotifier != null) pedidoNotifier.limparAtualizacao();
          context.push('/meuspedidos');
        }
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: buttonWidth,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLogout
                    ? [Colors.grey[700]!, Colors.grey[800]!]
                    : [cor.withOpacity(0.9), cor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: cor.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icone, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          if (temAtualizacao)
            Positioned(
              right: 18,
              top: 5,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}


/// -----------------------------------------------------------
/// 🔒 Diálogo de logout profissional
/// -----------------------------------------------------------
void confirmarLogout(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'LogoutDialog',
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
      CurvedAnimation(parent: animation, curve: Curves.easeInOut);
      return FadeTransition(
        opacity: curved,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black54),
            ),
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
                child: const _LogoutDialog(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// -----------------------------------------------------------
/// 🧩 Diálogo de Logout
/// -----------------------------------------------------------
class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog();

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    try {
      setState(() => _isLoading = true);
      final auth = Provider.of<AuthNotifier>(context, listen: false);
      await NotificationService.removeCurrentUserToken();

      if (!kIsWeb) {
        for (final topic in ['promocoes', 'novidades', 'avisos']) {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        }
      }

      await auth.logout();

      if (mounted) {
        Navigator.of(context).pop();
        context.go('/splash');
      }
    } catch (e) {
      debugPrint('❌ Erro ao encerrar sessão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Erro ao encerrar sessão. Tente novamente.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: const [
          Icon(Icons.logout, color: Colors.redAccent),
          SizedBox(width: 8),
          Text('Sair do Aplicativo',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
      content: Text(
        _isLoading
            ? 'Encerrando sua sessão...'
            : 'Tem certeza que deseja sair da sua conta?',
        style: const TextStyle(color: Colors.white70, fontSize: 15),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          icon: _isLoading
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Icon(Icons.exit_to_app),
          label: Text(_isLoading ? 'Saindo...' : 'Sair'),
        ),
      ],
    );
  }
}
