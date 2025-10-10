import 'package:flutter/material.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class PedidoItemCard extends StatelessWidget {
  final ItemCarrinho item;

  const PedidoItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Imagem do produto
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (item.produto.imageUrl != null &&
                  item.produto.imageUrl.isNotEmpty)
                  ? Image.network(
                item.produto.imageUrl.first,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: const Icon(Icons.shopping_bag,
                    size: 30, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),

            // 🔹 Informações principais
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do produto
                  Text(
                    item.produto.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Qtd: ${item.quantidade} ${item.produto.vendidoPorPeso ? 'kg' : 'un'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  if (item.acompanhamentos != null &&
                      item.acompanhamentos!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),

                  // Observação
                  if (item.observacao?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "Obs: ${item.observacao}",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 🔹 Preço
            Text(
              "R\$ ${item.subtotal.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
