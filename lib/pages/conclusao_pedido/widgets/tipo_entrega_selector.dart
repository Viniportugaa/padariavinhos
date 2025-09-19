import 'package:flutter/material.dart';
import '../controller/conclusao_pedido_controller.dart';

class TipoEntregaSelector extends StatelessWidget {
  final ConclusaoPedidoController controller;

  const TipoEntregaSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forma de Recebimento:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TipoEntrega.values.map((tipo) {
            String label = tipo == TipoEntrega.entrega
                ? 'Entrega'
                : tipo == TipoEntrega.retirada
                ? 'Retirada'
                : 'No Local';

            return ChoiceChip(
              label: Text(label),
              selected: controller.tipoEntrega == tipo,
              onSelected: (selected) {
                if (selected) {
                  controller.tipoEntrega = tipo;
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
