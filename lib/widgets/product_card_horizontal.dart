import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/models/produto.dart';

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
                          produto.vendidoPorPeso
                              ? 'R\$ ${produto.preco.toStringAsFixed(2)} (estimado)'
                              : 'R\$ ${produto.preco.toStringAsFixed(2)}',
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
