import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/widgets/pedido_detalhes_sheet.dart';

class MeuPedidoPage extends StatefulWidget {
  const MeuPedidoPage({super.key});

  @override
  State<MeuPedidoPage> createState() => _MeuPedidoPageState();
}

class _MeuPedidoPageState extends State<MeuPedidoPage> {
  String filtro = 'hoje';

  Stream<List<Pedido>> _pedidosStream(String userId) {
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));

    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .where('userId', isEqualTo: userId)
        .orderBy('data', descending: true);

    if (filtro == 'hoje') {
      final inicio = DateTime(hoje.year, hoje.month, hoje.day);
      final fim = inicio.add(const Duration(days: 1));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    } else if (filtro == 'semana') {
      final inicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
      final fim = inicio.add(const Duration(days: 7));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  void _abrirDetalhes(Pedido pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PedidoDetalhesSheet(pedido: pedido),
    );
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

  Color _statusBg(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange.withOpacity(0.15);
      case 'em preparo':
        return Colors.blue.withOpacity(0.15);
      case 'finalizado':
        return Colors.green.withOpacity(0.15);
      case 'cancelado':
        return Colors.red.withOpacity(0.12);
      default:
        return Colors.grey.withOpacity(0.08);
    }
  }

  String _formatarValor(double valor) => "R\$ ${valor.toStringAsFixed(2)}";

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthNotifier>(context).user?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não logado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          // filtro segmentado
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'hoje', label: Text('Hoje')),
                ButtonSegment(value: 'semana', label: Text('Semana')),
                ButtonSegment(value: 'todos', label: Text('Todos')),
              ],
              selected: {filtro},
              onSelectionChanged: (value) {
                setState(() => filtro = value.first);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith(
                      (states) => states.contains(MaterialState.selected)
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                      : Colors.grey.shade200,
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: StreamBuilder<List<Pedido>>(
                stream: _pedidosStream(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingList();
                  }

                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }

                  final pedidos = snapshot.data ?? [];
                  if (pedidos.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum pedido encontrado.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: ListView.builder(
                      key: ValueKey(filtro),
                      padding: const EdgeInsets.all(12),
                      itemCount: pedidos.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidos[index];
                        final dataFormatada =
                        DateFormat('dd/MM/yyyy HH:mm').format(pedido.data);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _abrirDetalhes(pedido),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _statusBg(pedido.status),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      pedido.status == 'finalizado'
                                          ? Icons.check
                                          : pedido.status == 'em preparo'
                                          ? Icons.kitchen
                                          : pedido.status == 'pendente'
                                          ? Icons.access_time
                                          : Icons.cancel,
                                      color: _statusColor(pedido.status),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Pedido #${pedido.numeroPedido}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              dataFormatada,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "Subtotal: ${_formatarValor(pedido.itens.fold(0.0, (s, i) => s + i.subtotal))}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            if (pedido.cupomAplicado != null)
                                              Text(
                                                pedido.cupomAplicado!.percentual
                                                    ? "Desconto: ${pedido.cupomAplicado!.desconto.toStringAsFixed(0)}%"
                                                    : "Desconto: R\$ ${pedido.cupomAplicado!.desconto.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Total: ${_formatarValor(pedido.totalFinal)}",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Chip(
                                    label: Text(
                                      pedido.status.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: _statusColor(pedido.status),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 10),
          Text(
            'Erro ao carregar pedidos',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}
