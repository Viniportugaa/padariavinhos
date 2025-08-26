import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/pedido_provider.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';

class PedidoCard extends StatelessWidget {
  const PedidoCard({super.key});

  Color _getCorDeFundo(pedido) {
    if (pedido.impresso && pedido.status == 'finalizado') return Colors.green.shade100;
    if (pedido.impresso && pedido.status == 'em preparo') return Colors.blue.shade100;
    if (!pedido.impresso && pedido.status == 'pendente') return Colors.yellow.shade100;
    return Colors.grey.shade200;
  }

  Color _getCorBorda(pedido) {
    if (pedido.impresso && pedido.status == 'finalizado') return Colors.green;
    if (pedido.impresso && pedido.status == 'em preparo') return Colors.blue;
    if (!pedido.impresso && pedido.status == 'pendente') return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, _) {
        final pedido = provider.pedido;
        if (pedido == null) return const SizedBox.shrink();

        final usuario = provider.usuario;
        final endereco = usuario != null
            ? "${usuario.endereco}, Nº ${usuario.numeroEndereco}${usuario.tipoResidencia == 'apartamento' && usuario.ramalApartamento != null ? ', Ap. ${usuario.ramalApartamento}' : ''} - CEP: ${usuario.cep}"
            : '';

        return Card(
          elevation: 4,
          color: _getCorDeFundo(pedido),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _getCorBorda(pedido), width: 2),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            title: Text('Pedido ${pedido.numeroPedido}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${usuario?.nome ?? pedido.nomeUsuario}'),
                if (endereco.isNotEmpty) Text('Endereço: $endereco'),
                Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.data)}'),
                Text('Status: ${pedido.status}'),
              ],
            ),
            trailing: Text('R\$ ${pedido.total.toStringAsFixed(2)}'),
            onTap: () => _mostrarDetalhesPedido(context, provider),
          ),
        );
      },
    );
  }

  void _mostrarDetalhesPedido(BuildContext context, PedidoProvider provider) {
    final pedido = provider.pedido;
    if (pedido == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pedido #${pedido.numeroPedido}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Cliente: ${provider.usuario?.nome ?? 'Carregando...'}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "Status: ${pedido.status}",
                style: TextStyle(
                  color: pedido.status == 'pendente'
                      ? Colors.orange
                      : pedido.status == 'em preparo'
                      ? Colors.blue
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              ...pedido.itens.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isVendidoPorPeso = item.produto.vendidoPorPeso;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),

                      if (isVendidoPorPeso)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item.quantidade.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Quantidade (kg)'),
                                enabled: pedido.status == 'pendente',
                                onChanged: (val) {
                                  final kg = double.tryParse(val.replaceAll(',', '.')) ?? 0;
                                  if (pedido.status != 'pendente') return;

                                  // Atualiza no Firestore via provider usando índice
                                  provider.atualizarItemPedidoPorIndice(index: index, quantidade: kg);

                                  // Atualiza localmente no carrinho
                                  final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
                                  item.quantidade = kg;
                                  carrinho.atualizarItem(item);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Valor por kg (Alterar se precisar)
                            // Expanded(
                            //   child: TextFormField(
                            //     initialValue: (item.valorFinal ?? item.produto.preco).toStringAsFixed(2),
                            //     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            //     decoration: const InputDecoration(labelText: 'Valor/kg'),
                            //     enabled: pedido.status == 'pendente',
                            //     onChanged: (val) {
                            //       final v = double.tryParse(val.replaceAll(',', '.')) ?? item.produto.preco;
                            //
                            //       // Atualiza o item no carrinho
                            //       final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
                            //       item.valorFinal = v;
                            //       carrinho.atualizarItem(item);
                            //     },
                            //   ),
                            // ),
                          ],
                        ),

                      if (!isVendidoPorPeso)
                        Text('Quantidade: ${item.quantidade % 1 == 0 ? item.quantidade.toInt() : item.quantidade}'),

                      // Subtotal
                      Consumer<CarrinhoProvider>(
                        builder: (_, carrinho, __) {
                          final subtotal = isVendidoPorPeso
                              ? ((item.valorFinal ?? item.produto.preco) * item.quantidade)
                              : item.subtotal;
                          return Text('Subtotal: R\$ ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold));
                        },
                      ),

                      const Divider(),
                    ],
                  ),
                );
              }),
              const Divider(),
              Wrap(
                spacing: 12,
                children: [
                  if (pedido.status == 'pendente')
                    ElevatedButton(onPressed: provider.editar, child: const Text('Marcar como Visto')),
                  if (pedido.status == 'em preparo')
                    ElevatedButton(onPressed: () => provider.imprimir(context), child: const Text('Imprimir')),
                  if (pedido.status == 'em preparo')
                    ElevatedButton(onPressed: provider.finalizar, child: const Text('Finalizar Pedido')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
