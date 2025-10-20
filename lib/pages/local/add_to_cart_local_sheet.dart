import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:padariavinhos/pages/local/provider/pedido_local_provider.dart';

void showAddToCartSheetLocal(
    BuildContext context,
    Produto produto,
    List<Acompanhamento> acompanhamentosDisponiveis,
    ) {
  int quantidade = 1;
  String observacoes = '';
  final List<Acompanhamento> selecionados =
  List.from(produto.acompanhamentosSelecionados ?? []);

  // Puxando a mesa e posição do provider
  final pedidoLocal = Provider.of<PedidoLocalProvider>(context, listen: false);
  final mesaSelecionada = pedidoLocal.numeroMesa ?? '';
  final posicaoSelecionada = pedidoLocal.posicaoMesa;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              final precoUnitario = PrecoHelper.calcularPrecoUnitario(
                produto: produto,
                selecionados: selecionados,
              );

              double precoAcompanhamentoCobrado(
                  Acompanhamento a,
                  List<Acompanhamento> selecionados,
                  Produto produto) {
                if (produto.category.toLowerCase() != 'pratos') return a.preco;
                if (selecionados.length <= 3) return 0.0;

                final numeroACobrar = selecionados.length - 3;
                final precosOrdenados =
                selecionados.map((e) => e.preco).toList()..sort();
                final valoresACobrar =
                precosOrdenados.take(numeroACobrar).toList();
                final Map<double, int> contagemValores = {};
                for (var v in valoresACobrar) {
                  contagemValores[v] = (contagemValores[v] ?? 0) + 1;
                }
                if (contagemValores.containsKey(a.preco) &&
                    contagemValores[a.preco]! > 0) {
                  contagemValores[a.preco] = contagemValores[a.preco]! - 1;
                  return a.preco;
                }
                return 0.0;
              }

              Widget quantidadeSelector() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: quantidade > 1
                        ? () => setState(() => quantidade--)
                        : null,
                  ),
                  Text(
                    '$quantidade',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => quantidade++),
                  ),
                ],
              );

              Widget acompanhamentosSelector() {
                if (acompanhamentosDisponiveis.isEmpty)
                  return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acompanhamentos:',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: acompanhamentosDisponiveis.map((a) {
                        final isSelected = selecionados.contains(a);
                        final precoExtra =
                        precoAcompanhamentoCobrado(a, selecionados, produto);
                        return AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ChoiceChip(
                                label: Text(a.nome),
                                selected: isSelected,
                                selectedColor: Colors.brown[200],
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selecionados.add(a);
                                    } else {
                                      selecionados.remove(a);
                                    }
                                  });
                                },
                              ),
                              if (precoExtra > 0 || isSelected)
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: precoExtra > 0
                                          ? Colors.red
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      precoExtra > 0
                                          ? '+R\$${precoExtra.toStringAsFixed(2)}'
                                          : 'GRÁTIS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10)),
                  ],
                ),

                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (produto.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            produto.imageUrl.first,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        produto.nome,
                        style: const TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'R\$ ${precoUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mostra apenas resumo da mesa selecionada no splash
                      if (mesaSelecionada.isNotEmpty && posicaoSelecionada != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.brown.shade200),
                          ),
                          child: Text(
                            'Mesa $mesaSelecionada | Posição P${posicaoSelecionada + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Observações (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (valor) => observacoes = valor,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      quantidadeSelector(),
                      const SizedBox(height: 16),
                      acompanhamentosSelector(),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: () {
                          if (mesaSelecionada.isEmpty || posicaoSelecionada == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Mesa e posição não definidas. Volte à tela inicial.',
                                ),
                              ),
                            );
                            return;
                          }

                          final novoItem = ItemCarrinho(
                            produto: produto,
                            quantidade: quantidade.toDouble(),
                            observacao:
                            'Mesa $mesaSelecionada | Posição P${posicaoSelecionada + 1} - $observacoes',
                            acompanhamentos: List.from(selecionados),
                            preco: precoUnitario,
                          );

                          pedidoLocal.adicionarItem(novoItem);

                          Navigator.of(context).pop();
                          DialogHelper.showTemporaryToast(
                            context,
                            'Adicionado: $quantidade x ${produto.nome} (Mesa $mesaSelecionada - P${posicaoSelecionada + 1})',
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Adicionar ao Pedido Local'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[600],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 16),
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
