import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/user.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onEditar;
  final VoidCallback onFinalizar;
  final VoidCallback onImprimir;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.onEditar,
    required this.onFinalizar,
    required this.onImprimir,
  });

  Color getCorDeFundo() {
    if (pedido.impresso == true && pedido.status == 'finalizado') {
      return Colors.green.shade100;
    } else if (pedido.impresso == true && pedido.status == 'em preparo') {
      return Colors.blue.shade100;
    } else if (pedido.impresso != true && pedido.status == 'pendente') {
      return Colors.yellow.shade100;
    }
    return Colors.grey.shade200;
  }

  Color getCorBorda() {
    if (pedido.impresso == true && pedido.status == 'finalizado') {
      return Colors.green;
    } else if (pedido.impresso == true && pedido.status == 'em preparo') {
      return Colors.blue;
    } else if (pedido.impresso != true && pedido.status == 'pendente') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  Future<User?> _buscarUsuario() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(pedido.userId)
        .get();
    if (!doc.exists) return null;
    return User.fromMap(doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(pedido.data);

    return FutureBuilder<User?>(
      future: _buscarUsuario(),
      builder: (context, snapshot) {
        final usuario = snapshot.data;
        final nomeUsuario = usuario?.nome ?? 'Carregando...';
        final endereco = usuario?.enderecoFormatado ?? '';

        return GestureDetector(
          onTap: () => _mostrarDetalhesPedido(context, pedido, onImprimir),
          child: Card(
            elevation: 4,
            color: getCorDeFundo(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: getCorBorda(), width: 2),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Lado esquerdo: informações do pedido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido ${pedido.numeroPedido}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text("Feito por: $nomeUsuario"),
                        if (endereco.isNotEmpty) Text("Endereço: $endereco"),
                        Text("Data: ${DateFormat('dd/MM/yyyy HH:mm').format(
                            pedido.data)}"),
                        Text("Status: ${pedido.status}"),
                      ],
                    ),
                  ),
                  // Lado direito: total do pedido
                  Text(
                    'R\$ ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🔹 ShowModal com detalhes do pedido
  void _mostrarDetalhesPedido(BuildContext context, Pedido pedido,
      VoidCallback onImprimir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<User?>(
          future: _buscarUsuario(), // busca o usuário
          builder: (context, userSnapshot) {
            final usuario = userSnapshot.data;
            final nomeUsuario = usuario?.nome ?? 'Carregando...';
            final endereco = usuario?.enderecoFormatado ?? '';

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .doc(pedido.id)
                  .snapshots(),
              builder: (context, pedidoSnapshot) {
                if (!pedidoSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pedidoAtualizado = Pedido.fromMap(
                  pedidoSnapshot.data!.data() as Map<String, dynamic>,
                  pedidoSnapshot.data!.id,
                );

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pedido #${pedidoAtualizado.numeroPedido}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Nome e endereço do cliente
                        Text(
                          "Cliente: $nomeUsuario",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (endereco.isNotEmpty)
                          Text("Endereço: $endereco"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              "Status: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              pedidoAtualizado.status,
                              style: TextStyle(
                                color: pedidoAtualizado.status == 'pendente'
                                    ? Colors.orange
                                    : pedidoAtualizado.status == 'em preparo'
                                    ? Colors.blue
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...pedidoAtualizado.itens.map((item) =>
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${item.quantidade}x ${item.produto.nome}"),
                                if (item.observacao != null &&
                                    item.observacao!.isNotEmpty)
                                  Text("Obs: ${item.observacao}"),
                                if (item.acompanhamentos != null &&
                                    item.acompanhamentos!.isNotEmpty)
                                  Text(
                                    "Acomp.: ${item.acompanhamentos!.map((
                                        a) => a.nome).join(', ')}",
                                  ),
                                const SizedBox(height: 8),
                              ],
                            )),
                        const Divider(),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (pedidoAtualizado.status == 'pendente')
                              ElevatedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('pedidos')
                                      .doc(pedidoAtualizado.id)
                                      .update({'status': 'em preparo'});
                                },
                                child: const Text('Marcar como Visto'),
                              ),
                            if (pedidoAtualizado.status == 'em preparo')
                              ElevatedButton(
                                onPressed: onImprimir,
                                child: const Text('Imprimir'),
                              ),
                            if (pedidoAtualizado.status == 'em preparo')
                              ElevatedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('pedidos')
                                      .doc(pedidoAtualizado.id)
                                      .update({'status': 'finalizado'});
                                },
                                child: const Text('Finalizar Pedido'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}