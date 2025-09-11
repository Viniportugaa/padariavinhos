import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // necessário para PointerDeviceKind
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/widgets/categorias_card.dart';

class ListaCategorias extends StatelessWidget {
  final List<String> categorias;
  final Function(String?) onSelecionarCategoria;

  const ListaCategorias({
    super.key,
    required this.categorias,
    required this.onSelecionarCategoria,
  });

  @override
  Widget build(BuildContext context) {
    final selecionada = context.watch<ProductsNotifier>().categoriaSelecionada;

    return SizedBox(
      height: 30,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categorias.length + 1, // botão "Todos"
          itemBuilder: (context, index) {
            if (index == 0) {
              return CategoriaCard(
                nome: 'Todos',
                icon: Icons.apps,
                selecionado: selecionada == null,
                onTap: () => onSelecionarCategoria(null),
              );
            }

            final nome = categorias[index - 1];
            return CategoriaCard(
              nome: nome,
              icon: _getIconForCategoria(nome),
              selecionado: nome == selecionada,
              onTap: () => onSelecionarCategoria(nome),
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForCategoria(String nome) {
    switch (nome.toLowerCase()) {
      case 'bolos': return Icons.cake;
      case 'paes': return Icons.bakery_dining;
      case 'sucos': return Icons.local_drink;
      case 'lanches': return Icons.fastfood;
      case 'refrigerante': return Icons.local_cafe;
      case 'doce': return Icons.icecream;
      case 'salgados': return Icons.add_circle_outline;
      case 'festividade': return Icons.celebration;
      case 'pratos': return Icons.restaurant;
      default: return Icons.add_circle;
    }
  }
}