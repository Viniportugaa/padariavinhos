import 'package:flutter/material.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'pedido_item_card.dart';
import 'pedido_total_row.dart';

class PedidoDetalhesSheet extends StatelessWidget {
  final Pedido pedido;
  const PedidoDetalhesSheet({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arraste
              Center(
                child: Container(
                  width: 60,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pedido #${pedido.numeroPedido}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      pedido.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: pedido.status == 'pendente'
                        ? Colors.amber
                        : pedido.status == 'em preparo'
                        ? Colors.blue
                        : pedido.status == 'finalizado'
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),

              const Divider(thickness: 1.2, height: 32),

              // Itens
              Text("Itens do Pedido", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...pedido.itens.map((item) => PedidoItemCard(item: item)),

              const Divider(thickness: 1.2, height: 32),

              // Totais
              TotalRow(label: "Subtotal", value: pedido.subtotal, destaque: false),
              TotalRow(label: "Frete", value: pedido.frete, destaque: false),
              TotalRow(
                label: "Total",
                value: pedido.totalFinal ?? pedido.totalComFrete,
                destaque: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
