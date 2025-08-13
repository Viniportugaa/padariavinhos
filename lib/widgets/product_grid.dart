import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Produto> produtos;
  final Function(Produto) onAddToCart;
  final Function(Produto)? onViewDetails;
  final ScrollController? scrollController;

  const ProductGrid({
    Key? key,
    required this.produtos,
    required this.onAddToCart,
    this.onViewDetails,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.45,
      ),
      itemCount: produtos.length,
      itemBuilder: (context, index) {
        final produto = produtos[index];
        return ProductCard(
          produto: produto,
          onAddToCart: () => onAddToCart(produto),
          onViewDetails: onViewDetails != null
              ? () => onViewDetails!(produto)
              : null,
        );
      },
    );
  }
}
