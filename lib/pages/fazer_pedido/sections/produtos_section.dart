import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/provider/favoritos_provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/widgets/product_card_horizontal.dart';
import 'package:padariavinhos/pages/fazer_pedido/sections/produto_detalhes_sheet.dart';
import '../add_to_cart_sheet.dart';

class ProdutosSection extends StatelessWidget {
  final String filtroNome;
  final List<Acompanhamento> acompanhamentos;
  final ScrollController? scrollController;

  const ProdutosSection({
    super.key,
    required this.filtroNome,
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
            child: Text('Sem conexão. Catálogo indisponível.'),
          );
        }

        if (productsNotifier.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtra produtos considerando favoritos
        List<Produto> produtosFiltrados =
        productsNotifier.produtosFiltrados(favoritosProvider);

        // Filtro por nome
        if (filtroNome.isNotEmpty) {
          produtosFiltrados = produtosFiltrados.where((produto) {
            return produto.nome.toLowerCase().contains(filtroNome) ||
                (produto.descricao != null &&
                    produto.descricao!.toLowerCase().contains(filtroNome));
          }).toList();
        }

        if (produtosFiltrados.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        // Agrupa produtos por categoria
        final Map<String, List<Produto>> produtosPorCategoria = {};
        for (var produto in produtosFiltrados) {
          final categoria = produto.category.isNotEmpty ? produto.category : 'Outros';
          produtosPorCategoria.putIfAbsent(categoria, () => []).add(produto);
        }

        final categoriasOrdenadas = produtosPorCategoria.keys.toList();

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categoriasOrdenadas.length,
          itemBuilder: (context, index) {
            final categoria = categoriasOrdenadas[index];
            final produtosDaCategoria = produtosPorCategoria[categoria]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    categoria,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pacifico',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...produtosDaCategoria.map((produto) {
                  return ProductCardHorizontal(
                    key: ValueKey(produto.id),
                    produto: produto,
                    onAddToCart: () => showAddToCartSheet(
                      context,
                      produto,
                      acompanhamentos
                          .where((a) => produto.acompanhamentosIds.contains(a.id))
                          .toList(),
                    ),
                    onViewDetails: () => showProdutoDetalhesSheet(
                      context,
                      produto,
                      acompanhamentos: acompanhamentos
                          .where((a) => produto.acompanhamentosIds.contains(a.id))
                          .toList(),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }
}
