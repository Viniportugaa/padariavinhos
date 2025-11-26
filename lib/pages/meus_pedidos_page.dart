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
  String filtroData = 'hoje';
  String filtroStatus = 'todos';

  Stream<List<Pedido>> _pedidosStream(String userId) {
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));

    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .where('userId', isEqualTo: userId);

    return query.snapshots().map((snapshot) {
      final pedidos = snapshot.docs
          .map((doc) =>
          Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // ------------------------------
      // FILTRO POR DATA
      // ------------------------------
      DateTime inicio;
      DateTime fim;

      if (filtroData == 'hoje') {
        inicio = DateTime(hoje.year, hoje.month, hoje.day);
        fim = inicio.add(const Duration(days: 1));
        pedidos.retainWhere((p) => p.data.isAfter(inicio) && p.data.isBefore(fim));
      } else if (filtroData == 'semana') {
        inicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
        fim = inicio.add(const Duration(days: 7));
        pedidos.retainWhere((p) => p.data.isAfter(inicio) && p.data.isBefore(fim));
      }

      // ------------------------------
      // FILTRO POR STATUS
      // ------------------------------
      if (filtroStatus != 'todos') {
        pedidos.retainWhere((p) => p.status == filtroStatus);
      }

      // ordena mais recentes primeiro
      pedidos.sort((a, b) => b.data.compareTo(a.data));

      return pedidos;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
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
          const SizedBox(height: 4),

          // ------------------------------
          // FILTRO POR DATA
          // ------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'hoje', label: Text('Hoje')),
                ButtonSegment(value: 'semana', label: Text('Semana')),
                ButtonSegment(value: 'todos', label: Text('Todos')),
              ],
              selected: {filtroData},
              onSelectionChanged: (value) {
                setState(() => filtroData = value.first);
              },
            ),
          ),

          // ------------------------------
          // FILTRO POR STATUS
          // ------------------------------
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _statusChip('todos', 'Todos'),
                _statusChip('pendente', 'Pendente'),
                _statusChip('em preparo', 'Em Preparo'),
                _statusChip('finalizado', 'Finalizado'),
                _statusChip('cancelado', 'Cancelado'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
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

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final dataFormatada =
                    DateFormat('dd/MM/yyyy HH:mm').format(pedido.data);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _abrirDetalhes(pedido),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: _statusColor(pedido.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // infos
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
                                    const SizedBox(height: 6),
                                    Text(
                                      "Total: R\$ ${pedido.totalFinal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = filtroStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.20),
        onSelected: (_) => setState(() => filtroStatus = value),
      ),
    );
  }

  void _abrirDetalhes(Pedido pedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PedidoDetalhesSheet(pedido: pedido),
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
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(
        "Erro: $message",
        textAlign: TextAlign.center,
      ),
    );
  }
}
