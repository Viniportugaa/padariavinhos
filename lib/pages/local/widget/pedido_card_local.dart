import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class PedidoCard extends StatelessWidget {
  final PedidoLocal pedido;
  final List<ItemCarrinho> itens;
  final Color statusColor;
  final VoidCallback onAvancar;
  final VoidCallback onImprimir;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.itens,
    required this.statusColor,
    required this.onAvancar,
    required this.onImprimir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mesa ${pedido.mesa} • Pedido ${pedido.posicao + 1}",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pedido.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 6),

            Text(
              DateFormat('HH:mm').format(pedido.data),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),

            const Divider(height: 20),

            // LISTA DE ITENS
            ...itens.map((i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${i.quantidade.toInt()}x ${i.produto.nome}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (i.observacao != null && i.observacao!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          "📝 ${i.observacao}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    if (i.acompanhamentos != null &&
                        i.acompanhamentos!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: i.acompanhamentos!
                              .map((a) => Text(
                            "• ${a.nome}",
                            style: const TextStyle(fontSize: 13),
                          ))
                              .toList(),
                        ),
                      )
                  ],
                ),
              );
            }),

            const Divider(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ${pedido.totalFormatado}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                // BOTÃO
                ElevatedButton.icon(
                  onPressed:
                  pedido.status == "pendente" ? onImprimir : onAvancar,
                  icon: Icon(
                    pedido.status == "pendente"
                        ? Icons.print
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    pedido.status == "pendente"
                        ? "Imprimir"
                        : "Avançar Status",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
