import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeuPedidoPage extends StatefulWidget {
  @override
  State<MeuPedidoPage> createState() => _MeuPedidoPageState();
}

class _MeuPedidoPageState extends State<MeuPedidoPage> {
  String filtro = 'hoje';
  final PedidoService _pedidoService = PedidoService();

  Color _corStatus(Pedido pedido) {
    if (pedido.impresso == true && pedido.status == 'finalizado') {
      return Colors.green.shade100;
    } else if (pedido.impresso == true && pedido.status == 'em preparo') {
      return Colors.blue.shade100;
    } else if (pedido.impresso != true && pedido.status == 'pendente') {
      return Colors.yellow.shade100;
    }
    return Colors.grey.shade100; // default
  }

  Stream<List<Pedido>> _pedidosStream(String userId){
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));

    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .where('userId', isEqualTo: userId)
        .orderBy('data', descending: true);

    if (filtro == 'hoje') {
      final inicio = DateTime(hoje.year, hoje.month, hoje.day);
      final fim = inicio.add(Duration(days: 1));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    } else if (filtro == 'semana') {
      final inicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
      final fim = inicio.add(Duration(days: 7));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    }


    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  void _mostrarDetalhesPedido(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pedido ${pedido.numeroPedido}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${pedido.status}'),
            const SizedBox(height: 8),
            const Text(
              'Itens:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...pedido.itens.map((item) => Text(
              '${item.quantidade}x ${item.produto.nome} - R\$ ${item.subtotal.toStringAsFixed(2)}',
            )),
            const SizedBox(height: 12),
            Text(
              'Total: R\$ ${pedido.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthNotifier>(context).user?.uid;
    if (userId == null) {
      return const Center(child: Text('Usuário não logado.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pedidos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButton<String>(
              value: filtro,
              items: const [
                DropdownMenuItem(value: 'hoje', child: Text('Hoje')),
                DropdownMenuItem(value: 'semana', child: Text('Semana')),
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    filtro = value;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Pedido>>(
              stream: _pedidosStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Erro ao carregar pedidos: ${snapshot.error}');
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
                      color: _corStatus(pedido),
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: ListTile(
                        title: Text('Pedido: ${pedido.numeroPedido}'),
                        subtitle: Text('Status: ${pedido.status}'),
                        trailing: pedido.impresso
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.hourglass_empty, color: Colors.orange),
                        onTap: () => _mostrarDetalhesPedido(pedido),
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
