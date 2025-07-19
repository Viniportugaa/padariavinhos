import 'package:flutter/material.dart';
import 'package:padariavinhos/router.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/services/product_service.dart';
import 'package:padariavinhos/services/transitions.dart';
import 'package:padariavinhos/services/product_service.dart';
import 'package:padariavinhos/widgets/product_grid.dart';
import 'package:padariavinhos/widgets/header_widget.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:padariavinhos/widgets/lista_categorias.dart';


class FazerPedidoPage extends StatefulWidget {

  @override
  State<FazerPedidoPage> createState() => _FazerPedidoPageState();
}

class _FazerPedidoPageState extends State<FazerPedidoPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsNotifier>(context, listen: false).load();
    });  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);

          if (carrinho.itens.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Seu carrinho está vazio!')),
            );
            return;
          }

          // Redireciona para a página de conclusão
          context.go('/conclusao-pedido');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pedido finalizado com sucesso!')),
          );
        },
        child: const Icon(Icons.check),
      ),
      // Corpo principal
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            // const SizedBox(height: 12),
            // _buildSearchField(),
            const SizedBox(height: 12),
            _buildCategorias(),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Produtos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<ProductsNotifier>(
                builder: (context, notifier, _) {
                  if (notifier.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (notifier.produtos.isEmpty) {
                    return const Center(child: Text('Nenhum produto disponível'));
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: ProductGrid(
                      key: ValueKey(notifier.categoriaSelecionada ?? 'todos'),
                      produtos: notifier.produtosFiltrados,
                      onAddToCart: (produto) => _showAddToCartSheet(context, produto),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSearchField() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 12),
  //     child: TextField(
  //       decoration: InputDecoration(
  //         hintText: 'Buscar...',
  //         prefixIcon: const Icon(Icons.search),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(30),
  //         ),
  //         contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCategorias() {
    final categorias = Provider.of<ProductsNotifier>(context).categoriasUnicas;

    return ListaCategorias(
      categorias: categorias,
      onSelecionarCategoria: (categoriaSelecionada) {
        Provider.of<ProductsNotifier>(context, listen: false)
            .filtrarPorCategoria(categoriaSelecionada);
      },
    );
  }

    // Título "Produtos"
  void _showAddToCartSheet(BuildContext context, Produto produto) {
    int quantidade = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(produto.nome,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),

                  // Controle de quantidade
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantidade > 1
                            ? () => setState(() => quantidade--)
                            : null,
                      ),
                      Text('$quantidade',
                          style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => quantidade++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botão para confirmar
                  ElevatedButton(
                    onPressed: () {
                      final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);

                      carrinho.adicionar(produto, quantidade);

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Adicionado: $quantidade x ${produto.nome}'),
                        ),
                      );
                    },
                    child: const Text('Adicionar ao Carrinho'),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
