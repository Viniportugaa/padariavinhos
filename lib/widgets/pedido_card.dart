import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/pedido_provider.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';

class PedidoCard extends StatefulWidget {
  final Pedido pedido;
  final User? usuario;

  const PedidoCard({super.key, required this.pedido, this.usuario});

  @override
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _cardColor(String status, bool impresso) {
    if (status == 'cancelado') return Colors.red.shade50;
    if (impresso && status == 'finalizado') return Colors.green.shade50;
    if (impresso && status == 'em preparo') return Colors.blue.shade50;
    if (!impresso && status == 'pendente') return Colors.yellow.shade50;
    return Colors.grey.shade100;
  }

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

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final usuario = widget.usuario;
    final endereco = usuario != null
        ? "${usuario.endereco}, Nº ${usuario.numeroEndereco}${usuario.tipoResidencia == 'apartamento' && usuario.ramalApartamento != null ? ', Ap. ${usuario.ramalApartamento}' : ''} - CEP: ${usuario.cep}"
        : '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: _cardColor(pedido.status, pedido.impresso),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pedido #${pedido.numeroPedido}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(pedido.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pedido.status.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Cliente: ${usuario?.nome ?? pedido.nomeUsuario}',
                    style: const TextStyle(fontSize: 14)),
                if (endereco.isNotEmpty)
                  Text('Endereço: $endereco',
                      style:
                      const TextStyle(fontSize: 14, color: Colors.black54)),
                Text(
                    'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.data)}',
                    style:
                    const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _mostrarDetalhesPedido(context, pedido, usuario),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ver Detalhes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalhesPedido(BuildContext context, Pedido pedido, User? usuario) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Consumer<PedidoProvider>(
            builder: (context, provider, _) {
              final endereco = usuario != null
                  ? "${usuario.endereco}, Nº ${usuario.numeroEndereco}${usuario.tipoResidencia == 'apartamento' && usuario.ramalApartamento != null ? ', Ap. ${usuario.ramalApartamento}' : ''} - CEP: ${usuario.cep}"
                  : '';

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text("Pedido #${pedido.numeroPedido}",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          "Cliente: ${usuario?.nome ?? pedido.nomeUsuario} (${usuario?.telefone ?? ''})",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (endereco.isNotEmpty)
                        Text("Endereço: $endereco",
                            style: const TextStyle(fontSize: 14)),
                      Chip(
                        label: Text(pedido.status.toUpperCase()),
                        backgroundColor: _statusColor(pedido.status),
                        labelStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Divider(thickness: 1.2, height: 24),

                      // Itens do pedido
                      ...pedido.itens.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isVendidoPorPeso = item.produto.vendidoPorPeso;

                        return Card(
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.produto.nome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),

                                if (isVendidoPorPeso)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                  ),

                                if (!isVendidoPorPeso)
                                  Text(
                                      'Quantidade: ${item.quantidade % 1 == 0 ? item.quantidade.toInt() : item.quantidade}'),

                                Text(
                                  "Preço Unitário: R\$ ${(item.preco).toStringAsFixed(2)}",
                                ),

                                if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty)
                                  Text("Acompanhamentos: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}"),

                                if (item.observacao?.isNotEmpty ?? false)
                                  Text("Obs: ${item.observacao}"),

                                const SizedBox(height: 4),

                                Text(
                                  "Subtotal: R\$ ${item.subtotal.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const Divider(thickness: 1.2, height: 24),
                      _buildTotalRow("Total", pedido.totalComFrete, true),
                      const SizedBox(height: 8),

                      // Forma de pagamento
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Método de Pagamento",
                                style: TextStyle(fontSize: 16)),
                            Text(
                              pedido.formaPagamento.isNotEmpty
                                  ? pedido.formaPagamento.first
                                  : "-",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Botões de ação
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Marcar como visto
                            if (!pedido.impresso && pedido.status == 'pendente')
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await provider.editar(pedido);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text("Marcar como visto"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange),
                              ),

                            // Imprimir pedido
                            if (!pedido.impresso && pedido.status == 'em preparo')
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (usuario == null) return;
                                  await provider.imprimir(
                                      pedido, usuario, context);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.print),
                                label: const Text("Imprimir"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue),
                              ),

                            // Finalizar pedido
                            if (pedido.status == 'em preparo')
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (!pedido.impresso) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Imprima antes de finalizar')));
                                    return;
                                  }
                                  await provider.finalizar(pedido);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.check),
                                label: const Text("Finalizar"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                              ),

                            // Cancelar pedido
                            if (pedido.status == 'pendente' ||
                                pedido.status == 'em preparo')
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Cancelar Pedido"),
                                      content: const Text(
                                          "Tem certeza que deseja cancelar este pedido?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Não"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Sim"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmar ?? false) {
                                    await provider.cancelarPedido(pedido);
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text("Cancelar"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, bool destaque) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: destaque ? 18 : 16,
                  fontWeight: destaque ? FontWeight.bold : FontWeight.normal)),
          Text(
            "R\$ ${value.toStringAsFixed(2)}",
            style: TextStyle(
                fontSize: destaque ? 18 : 16,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                color: destaque ? Colors.green : Colors.black),
          ),
        ],
      ),
    );
  }
}
