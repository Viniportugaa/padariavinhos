import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/provider/pedido_provider.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/user.dart';
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
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(_fadeAnimation);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _cardColor() {
    final status = widget.pedido.status;
    final impresso = widget.pedido.impresso;
    if (status == 'cancelado') return Colors.red.shade50;
    if (status == 'finalizado' && impresso) return Colors.green.shade50;
    if (status == 'em preparo' && impresso) return Colors.blue.shade50;
    if (status == 'pendente' && !impresso) return Colors.yellow.shade50;
    return Colors.grey.shade100;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pendente': return Colors.amber;
      case 'em preparo': return Colors.blue;
      case 'finalizado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatarValor(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final usuario = widget.usuario;

    final endereco = usuario != null
        ? "${usuario.endereco}, Nº ${usuario.numeroEndereco}" +
        (usuario.tipoResidencia == 'apartamento' && usuario.ramalApartamento != null
            ? ", Ap. ${usuario.ramalApartamento}" : "") +
        " - CEP: ${usuario.cep}"
        : pedido.endereco ?? '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: _cardColor(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pedido #${pedido.numeroPedido}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(pedido.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(pedido.status.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Cliente
                Text('Cliente: ${usuario?.nome ?? pedido.nomeUsuario}', style: const TextStyle(fontSize: 14)),
                if ((usuario?.telefone ?? pedido.telefone).isNotEmpty)
                  Text('Tel: ${usuario?.telefone ?? pedido.telefone}', style: const TextStyle(fontSize: 14)),
                if (endereco.isNotEmpty)
                  Text('Endereço: $endereco', style: const TextStyle(fontSize: 14, color: Colors.black54)),

                // Datas
                Text('Pedido: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.data)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                if (pedido.dataHoraEntrega != null)
                  Text('Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.dataHoraEntrega!)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),

                const SizedBox(height: 12),

                // Ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (pedido.status == 'pendente')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => context.read<PedidoProvider>().colocarEmPreparo(pedido),
                        child: const Text('Em preparo'),
                      ),
                    if (pedido.status == 'pendente' || pedido.status == 'em preparo')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => context.read<PedidoProvider>().cancelar(pedido),
                        child: const Text('Cancelar'),
                      ),
                    if (pedido.status == 'em preparo')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                        onPressed: () => context.read<PedidoProvider>().finalizar(pedido),
                        child: const Text('Finalizar'),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () => _imprimirPedido(pedido, usuario),
                      child: const Text('Imprimir'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _mostrarDetalhesPedido(context, pedido, usuario),
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

  Future<void> _imprimirPedido(Pedido pedido, User? usuario) async {
    try {
      final devices = await printer.getBondedDevices();
      if (devices.isEmpty) throw 'Nenhuma impressora encontrada';
      final device = devices.first;
      if (!(await printer.isConnected ?? false)) await printer.connect(device);

      String enderecoCompleto = usuario != null
          ? "${usuario.endereco}, Nº ${usuario.numeroEndereco}" +
          (usuario.tipoResidencia == "apartamento" && usuario.ramalApartamento != null
              ? ", Ap. ${usuario.ramalApartamento}" : "") +
          " - CEP: ${usuario.cep}"
          : pedido.endereco ?? '';

      printer.printNewLine();
      printer.printCustom("PADARIA VINHO'S", 3, 1);
      printer.printCustom("Pedido #${pedido.numeroPedido}", 2, 1);
      printer.printCustom("--------------------------------", 0, 1);
      printer.printCustom("Cliente: ${pedido.nomeUsuario}", 1, 0);
      printer.printCustom("Tel: ${pedido.telefone}", 1, 0);
      printer.printCustom("Endereço:", 1, 0);
      printer.printCustom(enderecoCompleto, 0, 0);
      printer.printCustom("Data: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.data)}", 1, 0);
      printer.printCustom("--------------------------------", 0, 1);
      printer.printCustom("Itens:", 1, 0);
      for (var item in pedido.itens) {
        printer.printLeftRight("${item.quantidade} x ${item.produto.nome}", _formatarValor(item.subtotal), 0);
        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty) {
          printer.printCustom("  Acomp: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}", 0, 0);
        }
        if (item.observacao?.isNotEmpty ?? false) {
          printer.printCustom("  Obs: ${item.observacao}", 0, 0);
        }
        printer.printCustom("--------------------------------", 0, 1);
      }
      printer.printLeftRight("Subtotal:", _formatarValor(pedido.subtotal), 1);
      printer.printLeftRight("Frete:", _formatarValor(pedido.frete), 1);
      printer.printCustom("TOTAL: ${_formatarValor(pedido.totalFinal)}", 2, 1);
      printer.printCustom("Status: ${pedido.status}", 1, 1);
      printer.printNewLine();
      printer.printQRcode("https://meuapp.com/pedido/${pedido.id}", 200, 200, 1);
      printer.printNewLine();
      printer.paperCut();

      pedido.impresso = true;
      if (pedido.status == 'pendente') await context.read<PedidoProvider>().colocarEmPreparo(pedido);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao imprimir: $e')));
    }
  }

  void _mostrarDetalhesPedido(BuildContext context, Pedido pedido, User? usuario) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => _DetalhesPedidoSheet(pedido: pedido, usuario: usuario, scrollController: scrollController),
      ),
    );
  }
}

// Componente separado para o modal
class _DetalhesPedidoSheet extends StatelessWidget {
  final Pedido pedido;
  final User? usuario;
  final ScrollController scrollController;

  const _DetalhesPedidoSheet({required this.pedido, this.usuario, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    Color _statusColor(String status) {
      switch (status) {
        case 'pendente': return Colors.amber;
        case 'em preparo': return Colors.blue;
        case 'finalizado': return Colors.green;
        case 'cancelado': return Colors.red;
        default: return Colors.grey;
      }
    }

    String _formatarValor(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

    Widget _buildTotalRow(String label, double value, bool destaque) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: destaque ? 18 : 16, fontWeight: destaque ? FontWeight.bold : FontWeight.w500)),
          Text(_formatarValor(value), style: TextStyle(fontSize: destaque ? 18 : 16, fontWeight: destaque ? FontWeight.bold : FontWeight.w600, color: destaque ? Colors.green.shade700 : Colors.black87)),
        ],
      ),
    );

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
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(12)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pedido #${pedido.numeroPedido}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Chip(label: Text(pedido.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: _statusColor(pedido.status)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person, color: Colors.black87),
                      title: Text(usuario?.nome ?? pedido.nomeUsuario, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(usuario?.telefone ?? pedido.telefone, style: const TextStyle(color: Colors.black54)),
                    ),
                    if (usuario != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(usuario!.enderecoFormatado, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1.2, height: 32),
            Text("Itens do Pedido", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...pedido.itens.map((item) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(item.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Qtd: ${item.quantidade}"),
                    if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty)
                      Text("Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}", style: const TextStyle(fontSize: 13)),
                    if (item.observacao?.isNotEmpty ?? false)
                      Text("Obs: ${item.observacao}", style: const TextStyle(fontSize: 13)),
                  ]),
                  trailing: Text(_formatarValor(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              );
            }).toList(),
            const Divider(thickness: 1.2, height: 32),
            _buildTotalRow("Subtotal", pedido.subtotal, false),
            _buildTotalRow("Frete", pedido.frete, false),
            _buildTotalRow("Total", pedido.totalFinal, true),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [Icon(Icons.payment, size: 20), SizedBox(width: 6), Text("Pagamento:", style: TextStyle(fontSize: 16))]),
                Text(pedido.formaPagamento.isNotEmpty ? pedido.formaPagamento.first : "-", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
