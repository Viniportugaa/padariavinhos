import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'pedido_total_row.dart';

class PedidoDetalhesSheet extends StatelessWidget {
  final Pedido pedido;
  const PedidoDetalhesSheet({super.key, required this.pedido});

  Color _statusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'em preparo':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  int _statusIndex(String status) {
    switch (status) {
      case 'pendente':
        return 0;
      case 'em preparo':
        return 1;
      case 'finalizado':
        return 2;
      default:
        return -1; // cancelado
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(pedido.data);
    final statusIndex = _statusIndex(pedido.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 🔹 Barra de arraste
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // 🔹 Conteúdo rolável
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Cabeçalho do pedido
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pedido #${pedido.numeroPedido}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Realizado em $dataFormatada",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            pedido.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: _statusColor(pedido.status),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Timeline de status
                    if (statusIndex >= 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Progresso do Pedido",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStep(
                                  icon: Icons.access_time,
                                  label: "Pendente",
                                  active: statusIndex >= 0,
                                  done: statusIndex > 0,
                                  color: Colors.orange),
                              _buildLine(statusIndex > 0),
                              _buildStep(
                                  icon: Icons.kitchen,
                                  label: "Em preparo",
                                  active: statusIndex >= 1,
                                  done: statusIndex > 1,
                                  color: Colors.blue),
                              _buildLine(statusIndex > 1),
                              _buildStep(
                                  icon: Icons.check_circle,
                                  label: "Finalizado",
                                  active: statusIndex >= 2,
                                  done: statusIndex > 2,
                                  color: Colors.green),
                            ],
                          ),
                          const Divider(thickness: 1.2, height: 32),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                const Icon(Icons.cancel,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 8),
                                Text(
                                  "Pedido Cancelado",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1.2, height: 32),
                        ],
                      ),

                    // 🔹 Itens do pedido
                    Text(
                      "Itens do Pedido",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...pedido.itens.map(
                          (item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            item.produto.nome,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "Qtd: ${item.quantidade}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Text(
                            "R\$ ${(item.preco * item.quantidade).toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(thickness: 1.2, height: 32),

                    // 🔹 Totais
                    Text(
                      "Resumo do Pedido",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            TotalRow(
                              label: "Subtotal",
                              value: pedido.subtotal,
                              destaque: false,
                            ),

                            // 🔹 Mostra desconto só se tiver cupom
                            if (pedido.cupomAplicado != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Desconto (${pedido.cupomAplicado!.codigo})",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  Text(
                                    pedido.cupomAplicado!.percentual
                                        ? "- ${pedido.cupomAplicado!.desconto.toStringAsFixed(0)}%"
                                        : "- R\$ ${pedido.cupomAplicado!.desconto.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 4),
                            TotalRow(
                              label: "Frete",
                              value: pedido.frete,
                              destaque: false,
                            ),
                            const Divider(),

                            // 🔹 Total final
                            TotalRow(
                              label: "Total",
                              value: pedido.totalFinal,
                              destaque: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      "Fechar",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Construtor de passo da timeline
  Widget _buildStep({
    required IconData icon,
    required String label,
    required bool active,
    required bool done,
    required Color color,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: done
              ? color
              : active
              ? color.withOpacity(0.2)
              : Colors.grey.shade300,
          child: Icon(
            icon,
            color: done || active ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: done || active ? color : Colors.grey,
            fontWeight: done ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 🔹 Linha da timeline
  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
    );
  }
}
