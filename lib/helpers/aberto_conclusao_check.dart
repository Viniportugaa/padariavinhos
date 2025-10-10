import 'package:flutter/material.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:provider/provider.dart';

/// Widget que impede o carregamento da página de conclusão de pedido
/// se a padaria estiver fechada ou se o carrinho estiver vazio.
class AbertoConclusaoChecker extends StatelessWidget {
  final Widget child;

  const AbertoConclusaoChecker({required this.child, super.key});

  String _formatarHora(TimeOfDay hora) {
    final hour = hora.hour.toString().padLeft(2, '0');
    final minute = hora.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigNotifier>();
    final carrinho = context.watch<CarrinhoProvider>();
    final aberto = config.abertoAgora;

    // 1️⃣ Padaria fechada
    if (!aberto) {
      final abertura = _formatarHora(config.horaAbertura);
      final fechamento = _formatarHora(config.horaFechamento);

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'A padaria está fechada.\nHorário de funcionamento: $abertura às $fechamento',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // 2️⃣ Carrinho vazio
    if (carrinho.itens.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Seu carrinho está vazio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // ✅ Tudo ok, mostra a página
    return child;
  }
}
