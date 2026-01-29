import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:padariavinhos/provider/provider_local/pedidos_balcao_provider.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

class PedidoCardLocal extends StatefulWidget {
  final PedidoLocal pedido;
  final List<ItemCarrinho> itens;

  final VoidCallback onImprimir;
  final VoidCallback onEditar;
  final Function(String novoStatus) onAlterarStatus;

  const PedidoCardLocal({
    super.key,
    required this.pedido,
    required this.itens,
    required this.onImprimir,
    required this.onEditar,
    required this.onAlterarStatus,
  });

  @override
  State<PedidoCardLocal> createState() => _PedidoCardLocalState();
}

class _PedidoCardLocalState extends State<PedidoCardLocal> {
  late Timer _timer;
  late Duration _tempoAberto;

  @override
  void initState() {
    super.initState();
    _tempoAberto = DateTime.now().difference(widget.pedido.data);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _tempoAberto = DateTime.now().difference(widget.pedido.data);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String getTempoFormatado() {
    final h = _tempoAberto.inHours;
    final m = _tempoAberto.inMinutes % 60;
    return h > 0 ? "$h h ${m.toString().padLeft(2, '0')} min" : "$m min";
  }

  Color getStatusColor() {
    switch (widget.pedido.status) {
      case "pendente":
        return Colors.orange;
      case "em preparo":
        return Colors.amber;
      case "pronto":
        return Colors.green;
      case "entregue":
        return Colors.blue;
      case "fechado":
        return Colors.grey;
      default:
        return Colors.brown;
    }
  }

  IconData getStatusIcon() {
    switch (widget.pedido.status) {
      case "pendente":
        return Icons.schedule;
      case "em preparo":
        return Icons.kitchen;
      case "pronto":
        return Icons.check_circle;
      case "entregue":
        return Icons.delivery_dining;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Card(
          elevation: 3,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalho(theme),
                const SizedBox(height: 12),
                _infoTempo(),
                const Divider(height: 32),
                _listaItens(),
                const Divider(height: 32),
                _rodape(isWide),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= CABEÇALHO =================
  Widget _cabecalho(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Mesa ${widget.pedido.mesa}",
            style: theme.textTheme.titleLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Chip(
          avatar: Icon(getStatusIcon(), size: 18, color: Colors.white),
          label: Text(
            widget.pedido.status.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: getStatusColor(),
        ),
      ],
    );
  }

  Widget _infoTempo() {
    return Row(
      children: [
        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          "há ${getTempoFormatado()}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          DateFormat('HH:mm').format(widget.pedido.data),
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ================= ITENS =================
  Widget _listaItens() {
    return Column(
      children: widget.itens.map(_itemPedido).toList(),
    );
  }

  Widget _itemPedido(ItemCarrinho i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.brown.shade100,
                child: Text(
                  "${i.quantidade.toInt()}x",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  i.produto.nome,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          if (i.acompanhamentos?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: -8,
                children: i.acompanhamentos!
                    .map((a) => Chip(
                  label: Text(a.nome),
                  visualDensity: VisualDensity.compact,
                ))
                    .toList(),
              ),
            ),

          if (i.observacao?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        i.observacao!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= RODAPÉ =================
  Widget _rodape(bool isWide) {
    final actions = [
      _acao(Icons.edit, "Editar", widget.onEditar),
      _acao(Icons.print, "Imprimir", widget.onImprimir),
      _acao(Icons.flag, "Status", () => _abrirSelecaoStatus(context)),
    ];

    return Column(
      children: [
        Row(
          children: [
            Text(
              "Total: ${widget.pedido.totalFormatado}",
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        isWide
            ? Row(
          children: actions
              .map((a) => Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: a,
          )))
              .toList(),
        )
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map((a) => SizedBox(width: 160, child: a))
              .toList(),
        ),
      ],
    );
  }

  Widget _acao(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _abrirSelecaoStatus(BuildContext context) {
    final statusList = ['pendente', 'em preparo', 'pronto', 'entregue', 'fechado'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          const Text(
            "Alterar Status",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...statusList.map(
                (s) => ListTile(
              leading: Icon(getStatusIcon()),
              title: Text(s.toUpperCase()),
              trailing: widget.pedido.status == s
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                widget.onAlterarStatus(s);
              },
            ),
          ),
        ],
      ),
    );
  }
}
