import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/widgets/pedido_total_row.dart';

class PedidoDetalhesSheet extends StatelessWidget {
  final Pedido pedido;
  const PedidoDetalhesSheet({super.key, required this.pedido});

  Color _statusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.amber;
      case 'em preparo':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
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
        return -1; // cancelado or unknown
    }
  }

  String _formatarValor(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

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
          backgroundColor: done ? color : (active ? color.withOpacity(0.2) : Colors.grey.shade300),
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

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
    );
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
            // handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pedido #${pedido.numeroPedido}",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Realizado em $dataFormatada",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(pedido.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: _statusColor(pedido.status),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // timeline / progress
                    if (statusIndex >= 0) ...[
                      Text("Progresso do Pedido", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildStep(
                            icon: Icons.access_time,
                            label: "Pendente",
                            active: statusIndex >= 0,
                            done: statusIndex > 0,
                            color: Colors.orange,
                          ),
                          _buildLine(statusIndex > 0),
                          _buildStep(
                            icon: Icons.kitchen,
                            label: "Em preparo",
                            active: statusIndex >= 1,
                            done: statusIndex > 1,
                            color: Colors.blue,
                          ),
                          _buildLine(statusIndex > 1),
                          _buildStep(
                            icon: Icons.check_circle,
                            label: "Finalizado",
                            active: statusIndex >= 2,
                            done: statusIndex > 2,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(thickness: 1.2, height: 28),
                    ] else ...[
                      // canceled or unknown
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.cancel, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              "Pedido Cancelado",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 🔹 exibe motivo do cancelamento, se houver
                            if (pedido.motivoCancelamento != null &&
                                pedido.motivoCancelamento!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Motivo: ${pedido.motivoCancelamento}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(thickness: 1.2, height: 28),
                    ],

                    // itens
                    Text("Itens do Pedido", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...pedido.itens.map((ItemCarrinho item) {
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.fastfood, size: 20, color: Colors.black54),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.produto.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text("Qtd: ${item.quantidade}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                        const SizedBox(width: 12),
                                        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty)
                                          Expanded(child: Text("Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                                      ],
                                    ),
                                    if (item.observacao?.isNotEmpty ?? false)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text("Obs: ${item.observacao}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(_formatarValor(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 12),
                    const Divider(thickness: 1.2, height: 28),

                    // resumo de valores
                    Text("Resumo do Pedido", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            // subtotal (calcula a partir dos itens se quiser, aqui uso pedido.totalFinal - frete + ... mas exibimos campos que existem)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Subtotal", style: TextStyle(fontSize: 15)),
                                Text(_formatarValor(pedido.itens.fold(0.0, (s, i) => s + (i.subtotal)))),
                              ],
                            ),

                            const SizedBox(height: 8),

                            if (pedido.cupomAplicado != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Desconto (${pedido.cupomAplicado!.codigo})", style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
                                  Text(
                                    pedido.cupomAplicado!.percentual
                                        ? "- ${pedido.cupomAplicado!.desconto.toStringAsFixed(0)}%"
                                        : "- R\$ ${pedido.cupomAplicado!.desconto.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Frete", style: TextStyle(fontSize: 15)),
                                Text(_formatarValor(pedido.frete)),
                              ],
                            ),

                            const Divider(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                Text(_formatarValor(pedido.totalFinal), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // pagamento / troco / tipo de entrega
                    Row(
                      children: [
                        const Icon(Icons.payment, color: Colors.black87),
                        const SizedBox(width: 8),
                        const Text("Pagamento:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          pedido.formaPagamento.isNotEmpty ? pedido.formaPagamento.first : "-",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    if (pedido.troco != null && pedido.troco! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on_outlined, color: Colors.green),
                            const SizedBox(width: 8),
                            Text("Troco para ${_formatarValor(pedido.troco!)}", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.local_shipping, color: Colors.black54),
                        const SizedBox(width: 8),
                        const Text("Entrega:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Text(pedido.tipoEntrega, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (pedido.dataHoraEntrega != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule, size: 18, color: Colors.black45),
                          const SizedBox(width: 6),
                          Text(DateFormat('dd/MM HH:mm').format(pedido.dataHoraEntrega!), style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ],
                    ),

                    const SizedBox(height: 28),
                    Center(child: Text("Obrigado por comprar na Padaria Vinho's 🍞", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic))),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text("Fechar", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
