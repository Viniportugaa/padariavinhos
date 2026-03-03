import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Timer? _timer;
  late Duration _tempoAberto;

  @override
  void initState() {
    super.initState();
    _calcularTempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _calcularTempo();
    });
  }

  @override
  void didUpdateWidget(covariant PedidoCardLocal oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.itens.length != widget.itens.length ||
        oldWidget.pedido.data != widget.pedido.data) {
      setState(() {});
    }
  }
  void _calcularTempo() {
    _tempoAberto = DateTime.now().difference(widget.pedido.data);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String getTempoFormatado() {
    final h = _tempoAberto.inHours;
    final m = _tempoAberto.inMinutes % 60;
    return h > 0 ? "$h h ${m.toString().padLeft(2, '0')} min" : "$m min";
  }

  Color getStatusColor(String status) {
    switch (status) {
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

  IconData getStatusIcon(String status) {
    switch (status) {
      case "pendente":
        return Icons.schedule;
      case "em preparo":
        return Icons.kitchen;
      case "pronto":
        return Icons.check_circle;
      case "entregue":
        return Icons.delivery_dining;
      case "fechado":
        return Icons.lock;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey(widget.pedido.id), // 🔥 ESSENCIAL
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
            _rodape(),
          ],
        ),
      ),
    );
  }

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
          avatar: Icon(
            getStatusIcon(widget.pedido.status),
            size: 18,
            color: Colors.white,
          ),
          label: Text(
            widget.pedido.status.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: getStatusColor(widget.pedido.status),
        ),
      ],
    );
  }

  Widget _infoTempo() {
    return Row(
      children: [
        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text("há ${getTempoFormatado()}",
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(DateFormat('HH:mm').format(widget.pedido.data),
            style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _listaItens() {
    return Column(
      children: widget.itens
          .map(
            (i) => KeyedSubtree(
          key: ValueKey('${widget.pedido.id}_${i.produto.id}'),
          child: _itemPedido(i),
        ),
      )
          .toList(),
    );
  }


  Widget _itemPedido(ItemCarrinho i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.brown.shade100,
            child: Text("${i.quantidade.toInt()}x",
                style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              i.produto.nome, // ✅ agora sempre renderiza
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rodape() {
    return Column(
      children: [
        Text(
          "Total: ${widget.pedido.totalFormatado}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _acao(Icons.edit, "Editar", widget.onEditar),
            _acao(Icons.print, "Imprimir", widget.onImprimir),
            _acao(Icons.flag, "Status", () => _abrirSelecaoStatus(context)),
          ],
        ),
      ],
    );
  }

  Widget _acao(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  void _abrirSelecaoStatus(BuildContext context) {
    const statusList = [
      'pendente',
      'em preparo',
      'pronto',
      'entregue',
      'fechado'
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(20),
        children: statusList
            .map((s) => ListTile(
          title: Text(s.toUpperCase()),
          onTap: () {
            Navigator.pop(context);
            widget.onAlterarStatus(s);
          },
        ))
            .toList(),
      ),
    );
  }
}
