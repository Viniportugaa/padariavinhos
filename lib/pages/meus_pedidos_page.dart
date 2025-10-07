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

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthNotifier>(context).user?.uid;
    if (userId == null) return const Center(child: Text('Usuário não logado.'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SizedBox(
              width: double.infinity,
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
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Lista de pedidos
          Expanded(
            child: StreamBuilder<List<Pedido>>(
              stream: _pedidosStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _abrirDetalhes(pedido),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Ícone do status
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: pedido.status == 'finalizado'
                                      ? Colors.green.withOpacity(0.15)
                                      : pedido.status == 'em preparo'
                                      ? Colors.blue.withOpacity(0.15)
                                      : pedido.status == 'pendente'
                                      ? Colors.orange.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
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
                                  color: pedido.status == 'finalizado'
                                      ? Colors.green
                                      : pedido.status == 'em preparo'
                                      ? Colors.blue
                                      : pedido.status == 'pendente'
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // 🔹 Infos principais
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pedido #${pedido.numeroPedido}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Data: $dataFormatada",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // 🔹 Subtotal
                                    Text(
                                      "Subtotal: R\$ ${pedido.subtotal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    // 🔹 Exibe desconto se houver cupom
                                    if (pedido.cupomAplicado != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "Desconto: ${pedido.cupomAplicado!.percentual ? "${pedido.cupomAplicado!.desconto.toStringAsFixed(0)}%" : "R\$ ${pedido.cupomAplicado!.desconto.toStringAsFixed(2)}"}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 4),

                                    // 🔹 Total final
                                    Text(
                                      "Total: R\$ ${pedido.totalFinal.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 🔹 Status como chip
                              Chip(
                                label: Text(
                                  pedido.status,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: pedido.status == 'finalizado'
                                    ? Colors.green
                                    : pedido.status == 'em preparo'
                                    ? Colors.blue
                                    : pedido.status == 'pendente'
                                    ? Colors.orange
                                    : Colors.red,
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
}
