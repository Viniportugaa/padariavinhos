// ———————————— IMPORTS —————————————
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

import 'widget/pedido_sidebar_filter.dart';
import 'widget/pedido_card_local.dart';

class PainelBalcaoPage extends StatefulWidget {
  const PainelBalcaoPage({super.key});

  @override
  State<PainelBalcaoPage> createState() => _PainelBalcaoPageState();
}

class _PainelBalcaoPageState extends State<PainelBalcaoPage> {
  String? filtroStatus;
  bool filtroHoje = true;

  bool sidebarAberta = true;
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool conectado = false;

  @override
  void initState() {
    super.initState();
    _conectarPrinter();
  }

  // ————————— PRINTER —————————
  Future<void> _conectarPrinter() async {
    try {
      final already = await bluetooth.isConnected;
      if (already == true) {
        setState(() => conectado = true);
        return;
      }
      final paired = await bluetooth.getBondedDevices();
      if (paired.isNotEmpty) {
        await bluetooth.connect(paired.first);
        setState(() => conectado = true);
      }
    } catch (_) {}
  }

  // ————————————— STATUS COLOR —————————————
  Color _statusColor(String s) {
    switch (s) {
      case 'pendente':
        return Colors.orange.shade700;
      case 'em preparo':
        return Colors.blue.shade700;
      case 'pronto':
        return Colors.green.shade700;
      case 'entregue':
        return Colors.grey.shade600;
      case 'fechado':
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }

  // ———————————— PROXIMO STATUS ———————————————
  String _proximo(String s) {
    switch (s) {
      case 'pendente':
        return 'em preparo';
      case 'em preparo':
        return 'pronto';
      case 'pronto':
        return 'entregue';
      default:
        return s;
    }
  }

  // ———————————— FIRESTORE QUERY ———————————————
  Query _gerarQuery() {
    Query q = FirebaseFirestore.instance
        .collection('pedidos_local')
        .orderBy('data', descending: true);

    // Aplicar filtro HOJE
    if (filtroHoje) {
      final inicio = DateTime.now();
      final diaIni = DateTime(inicio.year, inicio.month, inicio.day);
      q = q.where(
        'data',
        isGreaterThanOrEqualTo: Timestamp.fromDate(diaIni),
      );
    }

    // STATUS
    if (filtroStatus != null && filtroStatus!.isNotEmpty) {
      q = q.where('status', isEqualTo: filtroStatus);
    }

    return q;
  }

  // ————————— IMPRIMIR ——————————
  Future<bool> _imprimir(PedidoLocal pedido, List<ItemCarrinho> itens) async {
    try {
      if (!conectado) await _conectarPrinter();

      bluetooth.printCustom("PADARIA VINHOS", 3, 1);
      bluetooth.printCustom("MESA ${pedido.mesa}", 2, 1);
      bluetooth.printCustom("PEDIDO ${pedido.posicao + 1}", 2, 1);
      bluetooth.printCustom("---------------------", 1, 1);

      for (var i in itens) {
        bluetooth.printCustom("${i.quantidade.toInt()}x ${i.produto.nome}", 1, 0);
      }

      bluetooth.printCustom("---------------------", 1, 1);
      bluetooth.printNewLine();
      bluetooth.paperCut();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ———————————— BUILD ——————————————
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade400,
        centerTitle: true,
        title: const Text("Painel do Balcão"),
        actions: [
          IconButton(
            icon: Icon(
              sidebarAberta ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () => setState(() => sidebarAberta = !sidebarAberta),
          )
        ],
      ),

      body: Row(
        children: [
          // ———————————————— SIDEBAR ————————————————————
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: sidebarAberta ? 230 : 0,
            child: sidebarAberta
                ? PedidoSidebarFilter(
              filtroStatus: filtroStatus,
              filtroHoje: filtroHoje,
              onStatusChange: (v) => setState(() => filtroStatus = v),
              onHojeChange: (v) => setState(() => filtroHoje = v),
            )
                : null,
          ),

          // —————————————— CONTEÚDO ———————————————
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _gerarQuery().snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum pedido encontrado.",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final pedido =
                    PedidoLocal.fromMap(
                      Map<String, dynamic>.from(docs[i].data() as Map),
                      docs[i].id,
                    );

                    return FutureBuilder<List<ItemCarrinho>>(
                      future: PedidoLocal.carregarItens(pedido.id),
                      builder: (context, itensSnap) {
                        if (!itensSnap.hasData) {
                          return const SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final itens = itensSnap.data!;

                        return PedidoCard(
                          pedido: pedido,
                          itens: itens,
                          statusColor: _statusColor(pedido.status),
                          onImprimir: () async {
                            final ok = await _imprimir(pedido, itens);
                            if (ok) {
                              await FirebaseFirestore.instance
                                  .collection("pedidos_local")
                                  .doc(pedido.id)
                                  .update({
                                "status": "em preparo",
                              });
                            }
                          },
                          onAvancar: () async {
                            final novo = _proximo(pedido.status);
                            await FirebaseFirestore.instance
                                .collection("pedidos_local")
                                .doc(pedido.id)
                                .update({"status": novo});
                          },
                        );
                      },
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
