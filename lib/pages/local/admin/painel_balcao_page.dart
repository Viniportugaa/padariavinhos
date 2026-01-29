import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:go_router/go_router.dart';

import 'package:padariavinhos/provider/provider_local/pedidos_balcao_provider.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/pages/local/widget/modal_chamadas_garcom.dart';
import 'package:padariavinhos/pages/local/widget/pedido_sidebar_filter.dart';
import 'package:padariavinhos/pages/local/widget/pedido_card_local.dart';

class PainelBalcaoPage extends StatefulWidget {
  const PainelBalcaoPage({super.key});

  @override
  State<PainelBalcaoPage> createState() => _PainelBalcaoPageState();
}

class _PainelBalcaoPageState extends State<PainelBalcaoPage> {
  bool sidebarAberta = true;

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool conectado = false;

  @override
  void initState() {
    super.initState();
    context.read<PedidosBalcaoProvider>().startListeningPedidosHoje();
    _conectarPrinter();
  }

  // ================= PRINTER =================
  Future<void> _conectarPrinter() async {
    try {
      final already = await bluetooth.isConnected;
      if (already == true) {
        conectado = true;
        return;
      }

      final paired = await bluetooth.getBondedDevices();
      if (paired.isNotEmpty) {
        await bluetooth.connect(paired.first);
        conectado = true;
      }
    } catch (_) {}
  }

  // ================= STATUS COLOR =================
  Color _statusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.amber.shade700;
      case 'em_preparo':
        return Colors.blue.shade700;
      case 'pronto':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  // ================= PRÓXIMO STATUS =================
  String _proximoStatus(String atual) {
    switch (atual) {
      case 'pendente':
        return 'em_preparo';
      case 'em_preparo':
        return 'pronto';
      default:
        return atual;
    }
  }

  // ================= IMPRIMIR =================
  Future<bool> _imprimir(
      PedidoLocal pedido,
      List<ItemCarrinho> itens,
      ) async {
    try {
      if (!conectado) await _conectarPrinter();

      double total = 0;

      bluetooth.printCustom("PADARIA VINHOS", 3, 1);
      bluetooth.printCustom("MESA ${pedido.mesa}", 2, 1);
      bluetooth.printCustom(
        "PEDIDO ${pedido.posicao + 1}",
        2,
        1,
      );
      bluetooth.printCustom(
        DateFormat('dd/MM/yyyy HH:mm').format(pedido.data),
        1,
        1,
      );

      bluetooth.printCustom("--------------------------------", 1, 1);

      for (final item in itens) {
        final qtd = item.quantidade.toInt();
        final nome = item.produto.nome;
        final totalItem = item.subtotal;

        total += totalItem;

        bluetooth.printCustom(
          "${qtd}x $nome".padRight(22, '.') +
              totalItem.toStringAsFixed(2),
          1,
          0,
        );

        if (item.acompanhamentos != null) {
          for (final a in item.acompanhamentos!) {
            bluetooth.printCustom("   - ${a.nome}", 1, 0);
          }
        }

        if (item.observacao?.isNotEmpty == true) {
          bluetooth.printCustom(
            "   Obs: ${item.observacao}",
            1,
            0,
          );
        }

        bluetooth.printNewLine();
      }

      bluetooth.printCustom("--------------------------------", 1, 1);
      bluetooth.printCustom(
        "TOTAL: R\$ ${total.toStringAsFixed(2)}",
        2,
        1,
      );

      bluetooth.printNewLine();
      bluetooth.paperCut();

      return true;
    } catch (e) {
      debugPrint("Erro ao imprimir: $e");
      return false;
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade400,
        title: const Text('Painel do Balcão — Hoje'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Histórico',
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/historico_local'),
          ),
          IconButton(
            icon: Icon(sidebarAberta ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => sidebarAberta = !sidebarAberta),
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: sidebarAberta ? 230 : 0,
            child: sidebarAberta
                ? SidebarFilter(
              categorias: const [],
              selectedCategoria: null,
              onCategoriaChanged: (_) {},
              onSearchChanged: (_) {},
              onAbrirChamadasGarcom: () =>
                  ModalChamadasGarcom.abrir(context),
            )
                : null,
          ),
          Expanded(
            child: Consumer<PedidosBalcaoProvider>(
              builder: (context, provider, _) {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.pedidos.isEmpty) {
                  return const Center(
                    child: Text('Nenhum pedido hoje'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: provider.pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = provider.pedidos[index];

                    return FutureBuilder<List<ItemCarrinho>>(
                      future: provider.carregarItens(pedido.id),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final itens = snap.data!;

                        return SizedBox(
                          width: double.infinity, // 🔑 1 card por linha
                          child: PedidoCardLocal(
                            pedido: pedido,
                            itens: itens,

                            // ========= IMPRIMIR =========
                            onImprimir: () async {
                              await _imprimir(pedido, itens);
                            },

                            // ========= EDITAR =========
                            onEditar: () {
                              context.go(
                                '/editar_pedido_local/${pedido.id}',
                              );
                            },

                            // ========= ALTERAR STATUS =========
                            onAlterarStatus: (novoStatus) async {
                              if (pedido.status == 'pendente' &&
                                  novoStatus == 'em_preparo') {
                                final ok =
                                await _imprimir(pedido, itens);
                                if (!ok) return;
                              }

                              await provider.alterarStatus(
                                pedido.id,
                                novoStatus,
                              );
                            },
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
