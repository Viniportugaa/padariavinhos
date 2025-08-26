import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/widgets/pedido_card.dart';
import 'package:padariavinhos/services/pedido_provider.dart';

class ListaPedidosPage extends StatefulWidget {
  const ListaPedidosPage({super.key});

  @override
  State<ListaPedidosPage> createState() => _ListaPedidosPageState();
}

class _ListaPedidosPageState extends State<ListaPedidosPage> {
  String filtro = 'hoje';

  Stream<QuerySnapshot> _pedidosStream() {
    final hoje = DateTime.now();

    Query query = FirebaseFirestore.instance
        .collection('pedidos')
        .orderBy('data', descending: true);

    if (filtro == 'hoje') {
      final inicio = DateTime(hoje.year, hoje.month, hoje.day);
      final fim = inicio.add(const Duration(days: 1));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    } else if (filtro == 'semana') {
      final inicio = hoje.subtract(Duration(days: hoje.weekday - 1));
      final fim = inicio.add(const Duration(days: 7));
      query = query.where('data', isGreaterThanOrEqualTo: inicio, isLessThan: fim);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Pedidos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => filtro = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'hoje', child: Text('Hoje')),
              PopupMenuItem(value: 'semana', child: Text('Essa Semana')),
              PopupMenuItem(value: 'todos', child: Text('Todos')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _pedidosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum pedido encontrado.'));
          }

          final pedidos = snapshot.data!.docs
              .map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return ChangeNotifierProvider(
                key: ValueKey(pedido.id), // garante que cada provider seja único
                create: (_) => PedidoProvider(pedidoId: pedido.id),
                child: const PedidoCard(),
              );
            },
          );
        },
      ),
    );
  }
}
