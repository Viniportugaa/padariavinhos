import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/provider/favoritos_provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/pages/local/widget/product_card_quadrado.dart';

class ProdutosLocalSection extends StatelessWidget {
  final String filtroNome;
  final String? filtroCategoria;
  final List<Acompanhamento> acompanhamentos;
  final ScrollController? scrollController;

  const ProdutosLocalSection({
    super.key,
    required this.filtroNome,
    this.filtroCategoria,
    required this.acompanhamentos,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductsNotifier, FavoritosProvider>(
      builder: (context, productsNotifier, favoritosProvider, _) {
        final isOnline = Provider.of<AuthNotifier>(context).isOnline;

        if (!isOnline) {
          return const Center(
            child: Text(
              'Sem conexão. Catálogo indisponível.',
              style: TextStyle(color: Colors.brown),
            ),
          );
        }

        if (productsNotifier.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          );
        }

        // 🔹 Aplica filtros
        List<Produto> produtosFiltrados =
        productsNotifier.produtosFiltrados(favoritosProvider)
            .where((p) => p.disponivelLocal)
            .toList();

        if (filtroNome.isNotEmpty) {
          final search = filtroNome.toLowerCase();
          produtosFiltrados = produtosFiltrados.where((produto) {
            return produto.nome.toLowerCase().contains(search) ||
                (produto.descricao != null &&
                    produto.descricao!.toLowerCase().contains(search));
          }).toList();
        }

        if (filtroCategoria != null && filtroCategoria!.isNotEmpty) {
          produtosFiltrados = produtosFiltrados.where((produto) {
            final categoriaProduto =
            produto.category.isNotEmpty ? produto.category : 'Outros';
            return categoriaProduto == filtroCategoria;
          }).toList();
        }

        if (produtosFiltrados.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum produto encontrado.',
              style: TextStyle(color: Colors.brown),
            ),
          );
        }

        // 🔹 Agrupa por categoria
        final Map<String, List<Produto>> produtosPorCategoria = {};
        for (var produto in produtosFiltrados) {
          final categoria =
          produto.category.isNotEmpty ? produto.category : 'Outros';
          produtosPorCategoria.putIfAbsent(categoria, () => []).add(produto);
        }

        final categoriasOrdenadas = produtosPorCategoria.keys.toList();

        // 🔹 Lista principal
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: categoriasOrdenadas.length,
          itemBuilder: (context, index) {
            final categoria = categoriasOrdenadas[index];
            final produtosDaCategoria = produtosPorCategoria[categoria]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔸 Título da categoria
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.brown[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoria,
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Pacifico',
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                          shadows: [
                            Shadow(
                              color: Colors.black12,
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 🔸 Grid de produtos responsivo
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 🔹 Define colunas dinamicamente conforme a largura
                      int crossAxisCount;
                      double aspectRatio;

                      if (constraints.maxWidth >= 1400) {
                        crossAxisCount = 5;
                        aspectRatio = 1.0;
                      } else if (constraints.maxWidth >= 1100) {
                        crossAxisCount = 4;
                        aspectRatio = 1.0;
                      } else if (constraints.maxWidth >= 800) {
                        crossAxisCount = 3;
                        aspectRatio = 1.0;
                      } else if (constraints.maxWidth >= 600) {
                        crossAxisCount = 2;
                        aspectRatio = 1.0;
                      } else {
                        crossAxisCount = 1;
                        aspectRatio = 1.0;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: produtosDaCategoria.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: aspectRatio,
                        ),
                        itemBuilder: (context, i) {
                          final produto = produtosDaCategoria[i];
                          return AspectRatio(
                            aspectRatio: 1,
                            child: ProductCardQuadrado(
                              produto: produto,
                              acompanhamentos: acompanhamentos
                                  .where((a) =>
                                  produto.acompanhamentosIds.contains(a.id))
                                  .toList(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
