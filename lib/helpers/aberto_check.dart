import 'package:flutter/material.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import 'package:provider/provider.dart';

class AbertoChecker extends StatelessWidget {
  final Widget child;

  const AbertoChecker({required this.child, super.key});

  String _formatarHora(TimeOfDay hora) {
    final hour = hora.hour.toString().padLeft(2, '0');
    final minute = hora.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigNotifier>();
    final aberto = config.abertoAgora;

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

    return child;
  }
}
