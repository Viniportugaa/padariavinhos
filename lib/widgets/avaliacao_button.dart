import 'package:flutter/material.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/widgets/avaliacao_dialog.dart';

class AvaliacaoButton extends StatelessWidget {
  final Pedido pedido;

  const AvaliacaoButton({super.key, required this.pedido});

  bool get shouldShow {
    return pedido.status == 'finalizado' && !pedido.foiAvaliado;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.star, color: Colors.amber),
        label: const Text('Avaliar Pedido'),
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => AvaliacaoDialog(pedidoId: pedido.id),
          );

          // Pode receber true se avaliado com sucesso
          if (result == true) {
            // opcional: atualizar UI local (se necessário)
          }
        },
      ),
    );
  }
}
