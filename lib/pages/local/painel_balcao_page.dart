import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'widget/pedido_sidebar_filter.dart';

class PainelBalcaoPage extends StatefulWidget {
  const PainelBalcaoPage({super.key});

  @override
  State<PainelBalcaoPage> createState() => _PainelBalcaoPageState();
}

class _PainelBalcaoPageState extends State<PainelBalcaoPage> {
  String? filtroStatus;
  bool _sidebarAberta = true;
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  bool _conectado = false;

  @override
  void initState() {
    super.initState();
    _conectarImpressora();
  }

  Future<void> _conectarImpressora() async {
    try {
      final bool? conectado = await _bluetooth.isConnected;
      if (conectado == true) {
        setState(() => _conectado = true);
        return;
      }

      final List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      if (devices.isNotEmpty) {
        await _bluetooth.connect(devices.first);
        setState(() => _conectado = true);
      } else {
        debugPrint("Nenhum dispositivo emparelhado encontrado.");
      }
    } catch (e) {
      debugPrint("Erro ao conectar à impressora: $e");
    }
  }

  Future<void> _atualizarStatus(String id, String novoStatus) async {
    await FirebaseFirestore.instance
        .collection('pedidos_local')
        .doc(id)
        .update({'status': novoStatus});
  }

  /// 🔹 Imprime o pedido completo
  Future<bool> _imprimirPedido(PedidoLocal pedido, List<ItemCarrinho> itens) async {
    try {
      if (!_conectado) {
        await _conectarImpressora();
        if (!_conectado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Impressora não conectada.")),
          );
          return false;
        }
      }

      final format = NumberFormat.simpleCurrency(locale: 'pt_BR');

      _bluetooth.printCustom("PADARIA VINHOS", 3, 1);
      _bluetooth.printCustom("-----------------------------", 1, 1);
      _bluetooth.printCustom("MESA: ${pedido.mesa}", 2, 0);
      _bluetooth.printCustom(
        "PEDIDO N. ${pedido.posicao + 1}",
        2,
        0,
      );
      _bluetooth.printCustom(
        "HORARIO: ${DateFormat('HH:mm').format(pedido.data)}",
        1,
        0,
      );
      _bluetooth.printCustom("-----------------------------", 1, 1);

      // Itens
      for (var item in itens) {
        _bluetooth.printCustom(
            "${item.quantidade.toInt()}x ${item.produto.nome}", 1, 0);

        if (item.acompanhamentos != null && item.acompanhamentos!.isNotEmpty) {
          for (var acomp in item.acompanhamentos!) {
            _bluetooth.printCustom("   + ${acomp.nome}", 1, 0);
          }
        }

        if (item.observacao != null && item.observacao!.isNotEmpty) {
          _bluetooth.printCustom("   Obs: ${item.observacao}", 1, 0);
        }

        _bluetooth.printCustom("", 1, 0);
      }

      _bluetooth.printCustom("-----------------------------", 1, 1);
      _bluetooth.printCustom("Obrigado pela preferência!", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.paperCut();

      return true;
    } catch (e) {
      debugPrint("Erro ao imprimir pedido: $e");
      return false;
    }
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
        return Colors.grey.shade600;
      case 'fechado':
        return Colors.brown.shade400;
      default:
        return Colors.grey;
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
    Query query = FirebaseFirestore.instance.collection('pedidos_local');

    if (filtroStatus != null && filtroStatus!.isNotEmpty) {
      query = query.where('status', isEqualTo: filtroStatus);
    }

    query = query.orderBy('data', descending: true);

    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        title: const Text("Painel do Balcão"),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum pedido encontrado.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                final pedidos = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return PedidoLocal.fromMap(data, doc.id);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];

                    return FutureBuilder<List<ItemCarrinho>>(
                      future: PedidoLocal.carregarItens(pedido.id),
                      builder: (context, itensSnapshot) {
                        final itens = itensSnapshot.data ?? [];

                        return Card(
                          color: Colors.white,
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Mesa ${pedido.mesa} • Pedido ${pedido.posicao + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor(pedido.status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        pedido.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                const Divider(height: 20),

                                if (itensSnapshot.connectionState ==
                                    ConnectionState.waiting)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else
                                  Column(
                                    children: itens.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${item.quantidade.toInt()}x ${item.produto.nome}",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (item.observacao != null &&
                                                item.observacao!.isNotEmpty)
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(left: 8, top: 2),
                                                child: Text(
                                                  "📝 ${item.observacao}",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            if (item.acompanhamentos != null &&
                                                item.acompanhamentos!.isNotEmpty)
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(left: 8, top: 4),
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Acompanhamentos:",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.brown,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                    ...item.acompanhamentos!
                                                        .map(
                                                          (acomp) => Padding(
                                                        padding:
                                                        const EdgeInsets.only(left: 8, top: 1),
                                                        child: Text(
                                                          "• ${acomp.nome} (${NumberFormat.simpleCurrency(locale: 'pt_BR').format(acomp.preco)})",
                                                          style:
                                                          const TextStyle(fontSize: 13),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total: ${pedido.totalFormatado}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final novoStatus =
                                        _proximoStatus(pedido.status);

                                        if (pedido.status == 'pendente') {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content:
                                            Text("Imprimindo pedido..."),
                                            duration:
                                            Duration(milliseconds: 1500),
                                          ));

                                          final ok = await _imprimirPedido(
                                              pedido, itens);
                                          if (ok) {
                                            await _atualizarStatus(
                                                pedido.id, novoStatus);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Falha ao imprimir. Tente novamente."),
                                            ));
                                          }
                                        } else {
                                          await _atualizarStatus(
                                              pedido.id, novoStatus);
                                        }
                                      },
                                      icon: Icon(
                                        pedido.status == 'pendente'
                                            ? Icons.print
                                            : Icons.arrow_forward_rounded,
                                      ),
                                      label: Text(
                                        pedido.status == 'pendente'
                                            ? "Imprimir e Iniciar"
                                            : _proximoStatus(pedido.status),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        _statusColor(pedido.status),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

