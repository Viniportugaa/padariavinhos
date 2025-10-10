import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:padariavinhos/provider/pedido_provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PedidoCard extends StatefulWidget {
  final Pedido pedido;
  final User? usuario;

  const PedidoCard({super.key, required this.pedido, this.usuario});

  @override
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fadeAnimation);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -------------------- VISUAL SETTINGS --------------------

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

  Color _cardBackground() {
    final status = widget.pedido.status;
    if (status == 'cancelado') return Colors.red.shade50;
    if (status == 'finalizado') return Colors.green.shade50;
    if (status == 'em preparo') return Colors.blue.shade50;
    if (status == 'pendente') return Colors.yellow.shade50;
    return Colors.grey.shade100;
  }

  String _formatarValor(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final usuario = widget.usuario;

    final endereco = usuario != null
        ? "${usuario.endereco}, Nº ${usuario.numeroEndereco}" +
        (usuario.tipoResidencia == 'apartamento' &&
            usuario.ramalApartamento != null
            ? ", Ap. ${usuario.ramalApartamento}"
            : "") +
        " - CEP: ${usuario.cep}"
        : pedido.endereco ?? '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: _cardBackground(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ----------- Cabeçalho -----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          "Pedido #${pedido.numeroPedido}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Chip(
                      backgroundColor: _statusColor(pedido.status),
                      label: Text(
                        pedido.status.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ----------- Informações Cliente -----------
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        usuario?.nome ?? pedido.nomeUsuario,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if ((usuario?.telefone ?? pedido.telefone).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 26),
                    child: Text(
                      '📞 ${usuario?.telefone ?? pedido.telefone}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                if (endereco.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 26),
                    child: Text(
                      '📍 $endereco',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),

                const SizedBox(height: 10),

                // ----------- Datas -----------
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(pedido.data),
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    if (pedido.dataHoraEntrega != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.delivery_dining, size: 18, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(pedido.dataHoraEntrega!),
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ]
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(thickness: 1),

                // ----------- Totais -----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      _formatarValor(pedido.totalFinal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ----------- Ações -----------
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (pedido.status == 'pendente')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.kitchen),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () =>
                            context.read<PedidoProvider>().colocarEmPreparo(pedido),
                        label: const Text('Em Preparo'),
                      ),
                    if (pedido.status == 'em preparo')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () =>
                            context.read<PedidoProvider>().finalizar(pedido),
                        label: const Text('Finalizar'),
                      ),
                    if (pedido.status == 'pendente' || pedido.status == 'em preparo')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () =>
                            context.read<PedidoProvider>().cancelar(pedido),
                        label: const Text('Cancelar'),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (widget.usuario != null) {
                          context.read<PedidoProvider>().imprimirPedido(
                            widget.pedido,
                            widget.usuario!,
                            context,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuário não encontrado')),
                          );
                        }
                      },
                      label: const Text('Imprimir'),
                    ),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Ver Detalhes'),
                      onPressed: () => _mostrarDetalhesPedido(context, pedido, usuario),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
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
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => _DetalhesPedidoSheet(
          pedido: pedido,
          usuario: usuario,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
class _DetalhesPedidoSheet extends StatelessWidget {
  final Pedido pedido;
  final User? usuario;
  final ScrollController scrollController;

  const _DetalhesPedidoSheet({
    required this.pedido,
    this.usuario,
    required this.scrollController,
  });

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

  String _formatarValor(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

  Widget _buildTotalRow(String label, double value, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: destaque ? 18 : 15,
              fontWeight: destaque ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            _formatarValor(value),
            style: TextStyle(
              fontSize: destaque ? 18 : 15,
              fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
              color: destaque ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final endereco = usuario != null
        ? "${usuario!.endereco}, Nº ${usuario!.numeroEndereco}" +
        (usuario!.tipoResidencia == 'apartamento' &&
            usuario!.ramalApartamento != null
            ? ", Ap. ${usuario!.ramalApartamento}"
            : "") +
        " - CEP: ${usuario!.cep}"
        : pedido.endereco ?? '';

    return Container(
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
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

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
                  backgroundColor: _statusColor(pedido.status),
                  label: Text(
                    pedido.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          usuario?.nome ?? pedido.nomeUsuario,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if ((usuario?.telefone ?? pedido.telefone).isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            usuario?.telefone ?? pedido.telefone,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    if (endereco.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 18, color: Colors.redAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              endereco,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Data e forma de entrega
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  "Realizado em: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.data)}",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            if (pedido.dataHoraEntrega != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      "Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.dataHoraEntrega!)}",
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

            const Divider(thickness: 1.2, height: 32),

            // Itens do pedido
            Text(
              "Itens do Pedido",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...pedido.itens.map((item) {
              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.fastfood, color: Colors.black54, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.produto.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Qtd: ${item.quantidade}",
                                style: const TextStyle(fontSize: 13)),
                            if (item.acompanhamentos != null &&
                                item.acompanhamentos!.isNotEmpty)
                              Text(
                                "Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}",
                                style: const TextStyle(fontSize: 13),
                              ),
                            if (item.observacao?.isNotEmpty ?? false)
                              Text(
                                "Obs: ${item.observacao}",
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _formatarValor(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const Divider(thickness: 1.2, height: 32),

            // Totais
            _buildTotalRow("Subtotal", pedido.subtotal),
            _buildTotalRow("Frete", pedido.frete),
            _buildTotalRow("Total", pedido.totalFinal, destaque: true),

            const SizedBox(height: 20),

            // Pagamento
            Row(
              children: [
                const Icon(Icons.payment, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                const Text("Pagamento:",
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  pedido.formaPagamento.isNotEmpty
                      ? pedido.formaPagamento.first
                      : "-",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            if (pedido.troco != null && pedido.troco! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined,
                        color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      "Troco para ${_formatarValor(pedido.troco!)}",
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                "Obrigado por comprar na Padaria Vinho's 🍞",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
