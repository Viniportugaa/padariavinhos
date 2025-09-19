import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';


void showAddToCartSheet(BuildContext context, Produto produto, List<Acompanhamento> acompanhamentosDisponiveis) {
  int quantidade = 1;
  String observacoes = '';
  final List<Acompanhamento> selecionados = List.from(produto.acompanhamentosSelecionados ?? []);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {

              double precoUnitario = PrecoHelper.calcularPrecoUnitario(
                produto: produto,
                selecionados: selecionados,
              );

              double precoAcompanhamentoCobrado(Acompanhamento a) {
                if (produto.category.toLowerCase() == 'prato') {
                  if (selecionados.length <= 3) return 0;
                  final adicionais = List<Acompanhamento>.from(selecionados.sublist(3));
                  adicionais.sort((a, b) => a.preco.compareTo(b.preco));
                  final pos = adicionais.indexOf(a);
                  return pos != -1 ? adicionais[pos].preco : 0;
                } else {
                  return a.preco;
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Nome do produto
                      Text(
                        produto.nome,
                        style: const TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Preço
                      Text(
                        'R\$ ${precoUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Observações
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

                      // Quantidade
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: quantidade > 1 ? () => setState(() => quantidade--) : null,
                          ),
                          Text(
                            '$quantidade',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => quantidade++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Acompanhamentos
                      if (acompanhamentosDisponiveis.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Acompanhamentos:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: acompanhamentosDisponiveis.asMap().entries.map((entry) {
                                final a = entry.value;
                                final index = entry.key;
                                final isSelected = selecionados.contains(a);
                                final precoExtra = precoAcompanhamentoCobrado(a);

                                return AnimatedScale(
                                  scale: isSelected ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ChoiceChip(
                                        label: Text(a.nome),
                                        selected: isSelected,
                                        selectedColor: Colors.green[200],
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
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: precoExtra > 0 ? Colors.red : Colors.green,
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
                            const SizedBox(height: 4),
                            if (produto.category.toLowerCase() == 'prato' && selecionados.length > 3)
                              Text(
                                'A partir do 4º acompanhamento será cobrado o menor valor selecionado.',
                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Botão Adicionar ao Carrinho
                      ElevatedButton.icon(
                        onPressed: () {
                          final precoUnitario = PrecoHelper.calcularPrecoUnitario(
                            produto: produto,
                            selecionados: selecionados,
                          );
                          final total = precoUnitario * quantidade;

                          final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
                          carrinho.adicionarProduto(
                            produto,
                            quantidade.toDouble(),
                            observacao: observacoes,
                            acompanhamentos: selecionados,
                          );

                          final nomesSelecionados = selecionados.map((a) => a.nome).join(', ');

                          Navigator.of(context).pop();
                          DialogHelper.showTemporaryToast(
                            context,
                            'Adicionado: $quantidade x ${produto.nome}${nomesSelecionados.isNotEmpty ? ' com $nomesSelecionados' : ''}',
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Adicionar ao Carrinho'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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