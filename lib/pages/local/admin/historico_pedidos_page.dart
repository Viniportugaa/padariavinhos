import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/provider/provider_local//pedidos_balcao_provider.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/pages/local/widget/pedido_card_local.dart';

class HistoricoPedidosPage extends StatefulWidget {
  const HistoricoPedidosPage({super.key});

  @override
  State<HistoricoPedidosPage> createState() => _HistoricoPedidosPageState();
}

class _HistoricoPedidosPageState extends State<HistoricoPedidosPage> {
  String? filtroStatus;
  String? filtroMesa;

  @override
  void initState() {
    super.initState();
    context.read<PedidosBalcaoProvider>().listenPedidosAtivos();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'fechado':
        return Colors.green.shade700;
      case 'cancelado':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade400,
        title: const Text('Histórico de Pedidos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: Consumer<PedidosBalcaoProvider>(
              builder: (context, provider, _) {
                if (provider.loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final pedidos = provider.pedidosHistorico.where((p) {
                  if (filtroStatus != null &&
                      filtroStatus!.isNotEmpty &&
                      p.status != filtroStatus) return false;
                  if (filtroMesa != null &&
                      filtroMesa!.isNotEmpty &&
                      p.mesa != filtroMesa) return false;
                  return true;
                }).toList();

                if (pedidos.isEmpty) {
                  return const Center(
                    child: Text('Nenhum pedido encontrado'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final PedidoLocal pedido = pedidos[index];

                    return FutureBuilder<List<ItemCarrinho>>(
                      future: provider.carregarItens(pedido.id),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator()),
                          );
                        }

                        return PedidoCardLocal(
                          pedido: pedido,
                          itens: snap.data!,
                          onImprimir: () {},
                          onEditar: () {},
                          onAlterarStatus: (novoStatus) {
                            provider.alterarStatus(
                              pedido.id,
                              novoStatus,
                            );
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

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.brown.shade100,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: filtroStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'fechado', child: Text('Fechado')),
                DropdownMenuItem(
                    value: 'cancelado', child: Text('Cancelado')),
              ],
              onChanged: (v) => setState(() => filtroStatus = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Mesa',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => filtroMesa = v.trim().isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }
}
