import 'package:flutter/material.dart';

class PedidoMinimoAviso extends StatelessWidget {
  final double valorMinimo;

  const PedidoMinimoAviso({super.key, required this.valorMinimo});

  @override
  Widget build(BuildContext context) {
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
