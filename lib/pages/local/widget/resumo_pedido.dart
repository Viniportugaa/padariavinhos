import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/local/provider/pedido_local_provider.dart';

class ResumoPedido extends StatelessWidget {
  final VoidCallback onRevisarPedido;

  const ResumoPedido({super.key, required this.onRevisarPedido});

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoLocalProvider>(
      builder: (context, pedidoLocal, _) {
        final total = pedidoLocal.total;
        final quantidadeItens = pedidoLocal.itens.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))
            ],
          ),
          child: Column(
            children: [
              if (quantidadeItens > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$quantidadeItens item${quantidadeItens > 1 ? 's' : ''} - Total: R\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.brown),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRevisarPedido,
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: const Text(
                    'Revisar Pedido',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
