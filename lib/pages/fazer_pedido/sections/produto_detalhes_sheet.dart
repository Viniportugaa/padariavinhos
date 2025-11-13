import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/pages/fazer_pedido/add_to_cart_sheet.dart';
import 'package:go_router/go_router.dart';

void showProdutoDetalhesSheet(
    BuildContext context,
    Produto produto, {
      List<Acompanhamento>? acompanhamentos,
    }) {
  final List<Acompanhamento> _acompanhamentos = acompanhamentos ?? [];

  // Filtra apenas os acompanhamentos disponíveis para este produto
  final acompanhamentosDoProduto = _acompanhamentos
      .where((a) => produto.acompanhamentosIds.contains(a.id))
      .toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final List<Acompanhamento> selecionados =
          List.from(produto.acompanhamentosSelecionados ?? []);

          /// 🔹 Determina quais IDs de acompanhamentos serão cobrados
          List<String> idsAcompanhamentosCobrados(
              List<Acompanhamento> selecionados, Produto produto) {
            if (produto.category.toLowerCase() != 'pratos') {
              // Em categorias diferentes de 'pratos', todos são cobrados
              return selecionados.map((e) => e.id).whereType<String>().toList();
            }

            const int limiteGratis = 3;
            if (selecionados.length <= limiteGratis) return [];

            // Cobra apenas os que ultrapassam o limite gratuito
            final extras = selecionados.sublist(limiteGratis);
            return extras.map((e) => e.id).whereType<String>().toList();
          }

          final idsCobrados = idsAcompanhamentosCobrados(selecionados, produto);

          /// 💰 Calcula preço total (base + adicionais)
          double calcularPrecoTotal() {
            double base = produto.preco;
            double adicionais = 0.0;

            for (final a in selecionados) {
              if (idsCobrados.contains(a.id)) {
                adicionais += a.preco;
              }
            }
            return base + adicionais;
          }

          /// 📊 Gera resumo visual de acompanhamentos
          Map<String, dynamic> resumoAcompanhamentos() {
            int gratis = 0;
            int pagos = 0;
            double totalAdicionais = 0.0;

            for (final a in selecionados) {
              if (idsCobrados.contains(a.id)) {
                pagos++;
                totalAdicionais += a.preco;
              } else {
                gratis++;
              }
            }

            return {
              'gratis': gratis,
              'pagos': pagos,
              'totalAdicionais': totalAdicionais,
            };
          }

          final precoTotal = calcularPrecoTotal();
          final resumo = resumoAcompanhamentos();

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                left: 16,
                right: 16,
                top: 32,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// 🖼️ Imagem principal
                    if (produto.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Image.network(
                          produto.imageUrl.first,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            produto.nome,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            produto.descricao,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'R\$ ${precoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// Acompanhamentos disponíveis
                          if (acompanhamentosDoProduto.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Acompanhamentos disponíveis:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: acompanhamentosDoProduto.map((a) {
                                    final selecionado =
                                    selecionados.contains(a);

                                    final ehCobrado =
                                    idsCobrados.contains(a.id);
                                    final label = ehCobrado
                                        ? '${a.nome} (+R\$ ${a.preco.toStringAsFixed(2)})'
                                        : '${a.nome} (grátis)';

                                    return FilterChip(
                                      selected: selecionado,
                                      label: Text(label),
                                      labelStyle: TextStyle(
                                        color: selecionado
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      selectedColor: Colors.deepOrange,
                                      backgroundColor: Colors.grey[200],
                                      onSelected: (bool value) {
                                        setState(() {
                                          if (value) {
                                            selecionados.add(a);
                                          } else {
                                            selecionados.remove(a);
                                          }

                                          produto = produto.copyWith(
                                            acompanhamentosSelecionados:
                                            List.from(selecionados),
                                          );
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),

                                /// Resumo animado
                                AnimatedSwitcher(
                                  duration:
                                  const Duration(milliseconds: 300),
                                  child: selecionados.isEmpty
                                      ? const SizedBox()
                                      : Column(
                                    key: ValueKey(
                                        selecionados.length),
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Divider(
                                          color: Colors.grey[300]),
                                      Text(
                                        'Resumo:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        '${resumo['gratis']} grátis • ${resumo['pagos']} pagos (+R\$ ${resumo['totalAdicionais'].toStringAsFixed(2)})',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    /// Botão para adicionar ao carrinho ✅ CORRIGIDO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showAddToCartSheet(
                            context,
                            produto.copyWith(
                              acompanhamentosSelecionados:
                              List.from(selecionados),
                            ),
                            acompanhamentosDoProduto, // ✅ terceiro argumento
                          );
                        },
                        child: const Text(
                          'Adicionar ao carrinho',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
