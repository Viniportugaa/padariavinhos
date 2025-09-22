import 'package:flutter/material.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/pedido.dart';

class PedidoItemCard extends StatelessWidget {
  final ItemCarrinho item;

  const PedidoItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          item.produto.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Qtd: ${item.quantidade} ${item.produto.vendidoPorPeso ? 'unid' : 'un'}"),
            if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty)
              Text(
                "Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}",
                style: const TextStyle(fontSize: 13),
              ),
            if (item.observacao?.isNotEmpty ?? false)
              Text("Obs: ${item.observacao}", style: const TextStyle(fontSize: 13)),
          ],
        ),
        trailing: Text(
          "R\$ ${item.subtotal.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
