import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/widgets/pedido_card.dart';
import 'package:padariavinhos/services/pedido_provider.dart';
import 'dart:io';
import 'package:padariavinhos/models/user.dart';

class ListaPedidosPage extends StatefulWidget {
  const ListaPedidosPage({super.key});

  @override
  State<ListaPedidosPage> createState() => _ListaPedidosPageState();
}

class _ListaPedidosPageState extends State<ListaPedidosPage> {
  String filtro = 'hoje';

  // Cache de usuários para evitar múltiplos fetch
  final Map<String, User> _usuariosCache = {};

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

  Future<User?> _getUsuario(String userId) async {
    if (_usuariosCache.containsKey(userId)) return _usuariosCache[userId];

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final user = User.fromMap(doc.data()!);
      _usuariosCache[userId] = user; // adiciona no cache
      return user;
    }
    return null;
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

              return FutureBuilder<User?>(
                future: _getUsuario(pedido.userId),
                builder: (context, snapshotUsuario) {
                  final usuario = snapshotUsuario.data;
                  return PedidoCard(
                    pedido: pedido,
                    usuario: usuario,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
