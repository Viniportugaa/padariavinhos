import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class MeuPedidoPage extends StatefulWidget {
  @override
  State<MeuPedidoPage> createState() => _MeuPedidoPageState();
}

class _MeuPedidoPageState extends State<MeuPedidoPage> {
  String filtro = 'hoje';

  Color _corStatus(Pedido pedido) {
    if (pedido.status == 'cancelado') return Colors.red; // Novo status
    if (pedido.impresso && pedido.status == 'finalizado') return Colors.green;
    if (pedido.impresso && pedido.status == 'em preparo') return Colors.blue;
    if (!pedido.impresso && pedido.status == 'pendente') return Colors.yellow;
    return Colors.grey.shade100;
  }

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

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  void _mostrarDetalhesPedido(Pedido pedido) {
    // Se o pedido foi cancelado, exibe o dialog
    if (pedido.status == 'cancelado') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Pedido Cancelado"),
            content: const Text("Seu pedido foi cancelado. Por favor, entre em contato com a padaria: 1199999900"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text("Pedido #${pedido.numeroPedido}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Chip(
                  label: Text(pedido.status.toUpperCase()),
                  backgroundColor: pedido.status == 'pendente'
                      ? Colors.amber
                      : pedido.status == 'em preparo'
                      ? Colors.blue
                      : pedido.status == 'finalizado'
                      ? Colors.green
                      : Colors.red, // Cancelado
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Divider(thickness: 1.2, height: 24),
                ...pedido.itens.map((item) => Card(
                  color: Colors.grey.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("Quantidade: ${item.quantidade} ${item.produto.vendidoPorPeso ? 'Kg' : 'un'}"),
                        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty)
                          Text("Acompanhamentos: ${item.acompanhamentos!.join(', ')}"),
                        if (item.observacao?.isNotEmpty ?? false) Text("Obs: ${item.observacao}"),
                        const SizedBox(height: 4),
                        Text("Subtotal: R\$ ${item.subtotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )),
                const Divider(thickness: 1.2, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal", style: TextStyle(fontSize: 16)),
                    Text("R\$ ${pedido.subtotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Frete", style: TextStyle(fontSize: 16)),
                    Text("R\$ ${pedido.frete.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("R\$ ${(pedido.totalFinal ?? pedido.totalComFrete).toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
                if (value != null) setState(() => filtro = value);
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
                if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
                final pedidos = snapshot.data ?? [];
                if (pedidos.isEmpty) return const Center(child: Text('Nenhum pedido encontrado.'));

                return ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      color: _corStatus(pedido),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text('Pedido #${pedido.numeroPedido}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Total: R\$ ${(pedido.totalFinal ?? pedido.totalComFrete).toStringAsFixed(2)}'),
                        trailing: Icon(
                          pedido.impresso ? Icons.check_circle : Icons.hourglass_top,
                          color: pedido.impresso ? Colors.green : Colors.orange,
                        ),
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
