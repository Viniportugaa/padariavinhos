import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Produto> produtos;
  final Function(Produto) onAddToCart;

  const ProductGrid({
    Key? key,
    required this.produtos,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.5,
      ),
      itemCount: produtos.length,
      itemBuilder: (context, index) {
        final produto = produtos[index];
        return ProductCard(
          produto: produto,
          onAddToCart: () => onAddToCart(produto),
        );
      },
    );
  }
}
