import 'package:flutter/material.dart';
import 'package:padariavinhos/pages/conclusao_pedido/controller/conclusao_pedido_controller.dart';

class PedidoMinimoAviso extends StatelessWidget {
  final double valorMinimo;
  final TipoEntrega tipoEntrega;

  const PedidoMinimoAviso({
    super.key,
    required this.valorMinimo,
    required this.tipoEntrega,
  });

  @override
  Widget build(BuildContext context) {
    if (tipoEntrega != TipoEntrega.entrega) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'O pedido mínimo é de R\$ ${valorMinimo.toStringAsFixed(2)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
