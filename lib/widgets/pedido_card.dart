import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onEditar;
  final VoidCallback onFinalizar;
  final VoidCallback onImprimir;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.onEditar,
    required this.onFinalizar,
    required this.onImprimir,

  });

  Color getCorDeFundo() {
    if (pedido.impresso == true && pedido.status == 'finalizado') {
      return Colors.green.shade100;
    } else if (pedido.impresso == true && pedido.status == 'em preparo') {
      return Colors.blue.shade100;
    } else if (pedido.impresso != true && pedido.status == 'pendente') {
      return Colors.yellow.shade100;
    }
    return Colors.grey.shade200;
  }

  Color getCorBorda() {
    if (pedido.impresso == true && pedido.status == 'finalizado') {
      return Colors.green;
    } else if (pedido.impresso == true && pedido.status == 'em preparo') {
      return Colors.blue;
    } else if (pedido.impresso != true && pedido.status == 'pendente') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  IconData getIconStatus() {
    switch (pedido.status) {
      case 'pendente':
        return Icons.edit;
      case 'em preparo':
        return Icons.local_printshop;
      case 'finalizado':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String getTextoStatus() {
    switch (pedido.status) {
      case 'pendente':
        return 'Visto';
      case 'em preparo':
        return pedido.impresso == true ? 'Reimprimir' : 'Imprimir';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(pedido.data);

    return Card(
      elevation: 4,
      color: getCorDeFundo(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: getCorBorda(), width: 2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com data e total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido ${pedido.numeroPedido}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  pedido.endereco,
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'R\$ ${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dataFormatada,
              style: const TextStyle(color: Colors.black54),
            ),
            const Divider(height: 20),
            // Itens do pedido
            ...pedido.itens.map((item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.quantidade}x ${item.produto.nome}'),
                if (item.observacao != null &&
                    item.observacao!.trim().isNotEmpty)
                  Text('Obs: ${item.observacao!}'),
                if (item.acompanhamentos != null &&
                    item.acompanhamentos!.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: item.acompanhamentos!
                        .map((a) => Chip(
                      label: Text(a.nome),
                      visualDensity: VisualDensity.compact,
                    ))
                        .toList(),
                  ),
                const SizedBox(height: 6),
              ],
            )),
            const Divider(height: 20),
            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (pedido.status == 'pendente')
                  ElevatedButton.icon(
                    onPressed: onEditar,
                    icon: Icon(getIconStatus()),
                    label: Text(getTextoStatus()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getCorBorda(),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (pedido.status == 'em preparo')
                  ElevatedButton.icon(
                    onPressed: onImprimir,
                    icon: Icon(getIconStatus()),
                    label: Text(getTextoStatus()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getCorBorda(),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (pedido.status == 'em preparo') const SizedBox(width: 12),
                if (pedido.status == 'em preparo')
                  OutlinedButton.icon(
                    onPressed: onFinalizar,
                    icon: const Icon(Icons.check),
                    label: const Text('Finalizar'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green),
                      foregroundColor: Colors.green.shade800,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
