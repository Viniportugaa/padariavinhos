import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/notifiers/favoritos_provider.dart';
import 'package:padariavinhos/widgets/lista_categorias.dart';

class CategoriasSection extends StatelessWidget {
  final bool mostrar;

  const CategoriasSection({super.key, required this.mostrar});

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = Provider.of<FavoritosProvider>(context);
    final productsNotifier = Provider.of<ProductsNotifier>(context);
    final categorias = ['Favoritos', ...productsNotifier.categoriasUnicas];

    return AnimatedSlide(
      offset: mostrar ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: mostrar ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: ListaCategorias(
          categorias: categorias,
          onSelecionarCategoria: (categoriaSelecionada) {
            productsNotifier.filtrarPorCategoria(categoriaSelecionada);
          },
        ),
      ),
    );
  }
}