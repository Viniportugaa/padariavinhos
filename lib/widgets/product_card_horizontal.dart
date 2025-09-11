import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/favoritos_provider.dart';

class ProductCardHorizontal extends StatelessWidget {
  final Produto produto;
  final VoidCallback onAddToCart;
  final VoidCallback? onViewDetails;
  final Color cardColor; // cor do card

  const ProductCardHorizontal({
    super.key,
    required this.produto,
    required this.onAddToCart,
    this.onViewDetails,
    this.cardColor = Colors.white,
  });

  void _abrirImagemProduto(BuildContext context) {
    context.push(
      '/imagem-produto/${produto.id}',
      extra: produto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = context.watch<FavoritosProvider>();
    final isFavorito = favoritosProvider.isFavorito(produto.id);

    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _abrirImagemProduto(context),
                        child: Hero(
                          tag: produto.id,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: produto.imageUrl.isNotEmpty
                                ? Image.network(
                              produto.imageUrl.first,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  width: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            )
                            : Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (produto.vendidoPorPeso)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Por Peso',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          produto.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          produto.descricao ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${produto.preco.toStringAsFixed(2)}${produto.vendidoPorPeso ? ' (estimado)' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => context.read<FavoritosProvider>().toggleFavorito(produto),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFavorito ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onAddToCart,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ImagemProdutoPage extends StatelessWidget {
  final Produto produto;

  const ImagemProdutoPage({super.key, required this.produto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => context.pop(),
        child: Center(
          child: Hero(
            tag: produto.id,
            child: produto.imageUrl.isNotEmpty
                ? InteractiveViewer(
              child: Image.network(
                produto.imageUrl.first,
                fit: BoxFit.contain,
              ),
            )
                : const Icon(
              Icons.broken_image,
              size: 100,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
