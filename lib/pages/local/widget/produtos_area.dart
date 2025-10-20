import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/local/produto_local_section.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';

class ProdutosArea extends StatelessWidget {
  final String filtroNome;
  final String? filtroCategoria;
  final List<Acompanhamento> acompanhamentos;
  final ScrollController scrollController;

  const ProdutosArea({
    super.key,
    required this.filtroNome,
    required this.filtroCategoria,
    required this.acompanhamentos,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Consumer<ProductsNotifier>(
          builder: (context, productsNotifier, _) {
            return ProdutosLocalSection(
              filtroNome: filtroNome,
              acompanhamentos: acompanhamentos,
              scrollController: scrollController,
            );
          },
        ),
      ),
    );
  }
}
