import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';

class PainelBalcaoPage extends StatelessWidget {
  const PainelBalcaoPage({super.key});

  Future<void> _atualizarStatus(String pedidoId, String novoStatus) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .update({'status': novoStatus});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'em preparo':
        return Colors.amber;
      case 'pronto':
        return Colors.green;
      case 'entregue':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _proximoStatus(String status) {
    switch (status) {
      case 'pendente':
        return 'em preparo';
      case 'em preparo':
        return 'pronto';
      case 'pronto':
        return 'entregue';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel de Pedidos - Balcão"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('origem', isEqualTo: 'local')
            .orderBy('data', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum pedido local no momento."));
          }

          final pedidos = snapshot.data!.docs
              .map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text("Mesa ${pedido.mesa}",
                      //         style: const TextStyle(
                      //             fontSize: 20, fontWeight: FontWeight.bold)),
                      //     Container(
                      //       padding: const EdgeInsets.symmetric(
                      //           horizontal: 12, vertical: 6),
                      //       decoration: BoxDecoration(
                      //         color: _statusColor(pedido.status),
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //       child: Text(
                      //         pedido.status.toUpperCase(),
                      //         style: const TextStyle(
                      //             color: Colors.white,
                      //             fontWeight: FontWeight.bold),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pedido.itens.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                                "- ${item.quantidade}x ${item.produto.nome}"),
                          );
                        }).toList(),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total: R\$ ${pedido.totalFinal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          ElevatedButton(
                            onPressed: pedido.status == 'entregue'
                                ? null
                                : () async {
                              final novoStatus =
                              _proximoStatus(pedido.status);
                              await _atualizarStatus(pedido.id, novoStatus);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _statusColor(pedido.status),
                            ),
                            child: Text(
                              pedido.status == 'entregue'
                                  ? "Finalizado"
                                  : "Avançar (${_proximoStatus(pedido.status)})",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
