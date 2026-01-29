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
    final isOnline = context.select<AuthNotifier, bool>((a) => a.isOnline);

    if (!isOnline) {
      return const Center(
        child: Text(
          'Sem conexão. Catálogo indisponível.',
          style: TextStyle(color: Colors.brown),
        ),
      );
    }

    return Consumer2<ProductsNotifier, FavoritosProvider>(
      builder: (context, productsNotifier, favoritosProvider, _) {
        if (productsNotifier.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          );
        }

        final produtosFiltrados = _filtrarProdutos(
          productsNotifier: productsNotifier,
          favoritosProvider: favoritosProvider,
        );

        if (produtosFiltrados.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum produto encontrado.',
              style: TextStyle(color: Colors.brown),
            ),
          );
        }

        final produtosPorCategoria = _agruparPorCategoria(produtosFiltrados);
        final categorias = produtosPorCategoria.keys.toList();

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            final categoria = categorias[index];
            final produtos = produtosPorCategoria[categoria]!;

            return _CategoriaSection(
              categoria: categoria,
              produtos: produtos,
              acompanhamentos: acompanhamentos,
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 🔹 FILTROS
  // ===========================================================================
  List<Produto> _filtrarProdutos({
    required ProductsNotifier productsNotifier,
    required FavoritosProvider favoritosProvider,
  }) {
    var lista = productsNotifier
        .produtosFiltrados(favoritosProvider)
        .where((p) => p.disponivelLocal)
        .toList();

    if (filtroNome.isNotEmpty) {
      final search = filtroNome.toLowerCase();
      lista = lista.where((p) {
        return p.nome.toLowerCase().contains(search) ||
            (p.descricao?.toLowerCase().contains(search) ?? false);
      }).toList();
    }

    if (filtroCategoria != null && filtroCategoria!.isNotEmpty) {
      lista = lista.where((p) {
        final categoria = p.category.isNotEmpty ? p.category : 'Outros';
        return categoria == filtroCategoria;
      }).toList();
    }

    return lista;
  }

  // ===========================================================================
  // 🔹 AGRUPAMENTO
  // ===========================================================================
  Map<String, List<Produto>> _agruparPorCategoria(List<Produto> produtos) {
    final Map<String, List<Produto>> mapa = {};

    for (final produto in produtos) {
      final categoria =
      produto.category.isNotEmpty ? produto.category : 'Outros';
      mapa.putIfAbsent(categoria, () => []).add(produto);
    }

    return mapa;
  }
}
class _CategoriaSection extends StatelessWidget {
  final String categoria;
  final List<Produto> produtos;
  final List<Acompanhamento> acompanhamentos;

  const _CategoriaSection({
    required this.categoria,
    required this.produtos,
    required this.acompanhamentos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoriaTitulo(categoria: categoria),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _GridLayout.fromWidth(constraints.maxWidth);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: produtos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: layout.colunas,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: layout.aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final produto = produtos[index];

                  final acompDoProduto = acompanhamentos
                      .where((a) =>
                      produto.acompanhamentosIds.contains(a.id))
                      .toList();

                  return ProductCardQuadrado(
                    key: ValueKey(produto.id),
                    produto: produto,
                    acompanhamentos: acompDoProduto,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
class _CategoriaTitulo extends StatelessWidget {
  final String categoria;

  const _CategoriaTitulo({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}
class _GridLayout {
  final int colunas;
  final double aspectRatio;

  const _GridLayout(this.colunas, this.aspectRatio);

  factory _GridLayout.fromWidth(double width) {
    if (width >= 1400) return const _GridLayout(6, 0.5);
    if (width >= 1100) return const _GridLayout(5, 1.0);
    if (width >= 800) return const _GridLayout(4, 0.5);
    if (width >= 600) return const _GridLayout(4, 0.5);
    return const _GridLayout(1, 1.0);
  }
}
