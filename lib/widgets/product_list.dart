import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'product_card_widget.dart';
import 'package:go_router/go_router.dart';

class ProductList extends StatelessWidget {
  final List<Produto> produtos;
  final void Function(Produto produto) onAddToCart;
  final ScrollController? scrollController;
  final void Function(Produto produto) onViewDetails;

  const ProductList({
    super.key,
    required this.produtos,
    required this.onAddToCart,
    required this.onViewDetails,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: produtos.length,
      itemBuilder: (context, index) {
        final produto = produtos[index];
        return ProductCardWidget(
          produto: produto,
          onAddToCart: () =>  onAddToCart(produto),
          onViewDetails: () => context.go('/produto/${produto.id}'),
        );
      },
    );
  }
}
