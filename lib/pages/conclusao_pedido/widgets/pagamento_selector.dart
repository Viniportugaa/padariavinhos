import 'package:flutter/material.dart';
import '../controller/conclusao_pedido_controller.dart';
import 'glass_card.dart';

class PagamentoSelector extends StatelessWidget {
  final ConclusaoPedidoController controller;

  const PagamentoSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.payment, color: Colors.green),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Forma de Pagamento (Feito no local):',
              style: TextStyle(fontSize: 16),
            ),
          ),
          DropdownButton<String>(
            value: controller.formaPagamento,
            items: controller.formasPagamento
                .map((f) => DropdownMenuItem(
              value: f,
              child: Text(f),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.formaPagamento = value;
              }
            },
          ),
        ],
      ),
    );
  }
}
