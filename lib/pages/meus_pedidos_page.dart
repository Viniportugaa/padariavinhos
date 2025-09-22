import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      appBar: AppBar(title: const Text('Meus Pedidos')),
      body: Column(
        children: [
          // Filtro
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButton<String>(
              value: filtro,
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: 'hoje', child: Text('Hoje')),
                DropdownMenuItem(value: 'semana', child: Text('Semana')),
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => filtro = value);
              },
            ),
          ),

          // Lista de pedidos
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
                  return const Center(child: Text('Nenhum pedido encontrado.'));
                }

                return ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(
                          'Pedido #${pedido.numeroPedido}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Total: R\$ ${(pedido.totalFinal ?? pedido.totalComFrete).toStringAsFixed(2)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              pedido.status == 'finalizado'
                                  ? Icons.check_circle
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
                            const SizedBox(height: 4),
                            Text(
                              pedido.status,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () => _abrirDetalhes(pedido),
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
