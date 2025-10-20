import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'widget/pedido_sidebar_filter.dart';

class PainelBalcaoPage extends StatefulWidget {
  const PainelBalcaoPage({super.key});

  @override
  State<PainelBalcaoPage> createState() => _PainelBalcaoPageState();
}

class _PainelBalcaoPageState extends State<PainelBalcaoPage> {
  String? filtroStatus;
  bool _sidebarAberta = true;

  Future<void> _atualizarStatus(String id, String novoStatus) async {
    await FirebaseFirestore.instance
        .collection('pedidos_local')
        .doc(id)
        .update({'status': novoStatus});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange.shade600;
      case 'em preparo':
        return Colors.blueAccent.shade700;
      case 'pronto':
        return Colors.green.shade600;
      case 'entregue':
        return Colors.grey.shade500;
      default:
        return Colors.brown.shade400;
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
    // 🔹 Filtra apenas os pedidos de hoje
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final fimHoje = inicioHoje.add(const Duration(days: 1));

    final query = FirebaseFirestore.instance
        .collection('pedidos_local')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoje))
        .where('data', isLessThan: Timestamp.fromDate(fimHoje))
        .orderBy('data', descending: false);

    final stream = filtroStatus == null
        ? query.snapshots()
        : query.where('status', isEqualTo: filtroStatus).snapshots();

    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text("Pedidos do Dia - Balcão"),
        centerTitle: true,
        backgroundColor: Colors.brown.shade400,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              _sidebarAberta ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _sidebarAberta = !_sidebarAberta),
          ),
        ],
      ),
      body: Row(
        children: [
          // 🔹 Sidebar filtragem
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarAberta ? 220 : 0,
            child: _sidebarAberta
                ? PedidoSidebarFilter(
              filtroSelecionado: filtroStatus,
              onFiltroChanged: (novo) =>
                  setState(() => filtroStatus = novo),
            )
                : null,
          ),

          // 🔹 Lista de pedidos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum pedido encontrado hoje.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                final pedidos = snapshot.data!.docs
                    .map((doc) => PedidoLocal.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Cabeçalho do pedido
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Mesa ${pedido.mesa} | P${pedido.posicao + 1}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _statusColor(pedido.status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    pedido.status.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(pedido.data),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                            const Divider(),

                            // 🔹 Itens do pedido
                            ...pedido.itens.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${item.quantidade.toInt()}x ${item.produto.nome}"),
                                  if (item.acompanhamentos != null &&
                                      item.acompanhamentos!.isNotEmpty)
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(left: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: item.acompanhamentos!
                                            .map((a) => Text(
                                            "- ${a.nome} (${a.preco > 0 ? '+R\$${a.preco.toStringAsFixed(2)}' : 'grátis'})",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54)))
                                            .toList(),
                                      ),
                                    ),
                                  if (item.observacao != null &&
                                      item.observacao!.trim().isNotEmpty)
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(left: 12),
                                      child: Text(
                                        "Obs: ${item.observacao}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.brown),
                                      ),
                                    ),
                                ],
                              ),
                            )),
                            const Divider(),

                            // 🔹 Total + botão alterar status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total: ${pedido.totalFormatado}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                ElevatedButton.icon(
                                  onPressed: pedido.status == 'entregue'
                                      ? null
                                      : () async {
                                    final novo =
                                    _proximoStatus(pedido.status);
                                    await _atualizarStatus(
                                        pedido.id, novo);
                                  },
                                  icon: const Icon(Icons.arrow_forward),
                                  label:
                                  Text(_proximoStatus(pedido.status)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    _statusColor(pedido.status),
                                    foregroundColor: Colors.white,
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
