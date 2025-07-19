import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';

class ProductCard extends StatefulWidget {
  final Produto produto;
  final VoidCallback onAddToCart;

  const ProductCard({
    Key? key,
    required this.produto,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}
class _ProductCardState extends State<ProductCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && widget.produto.imageUrl.isNotEmpty) {
        _currentPage = (_currentPage + 1) % widget.produto.imageUrl.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Image.network(
        'https://via.placeholder.com/150',
        fit: BoxFit.cover,
      );
    } else {
      // Se as imagens forem assets, use Image.asset;
      // se forem URLs, use Image.network (aqui está usando asset como no seu exemplo)
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: PageView.builder(
              controller: _pageController,
              itemCount: produto.imageUrl.length,
              itemBuilder: (context, index) =>
                  _buildImage(produto.imageUrl[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto.nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${produto.preco.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: widget.onAddToCart,
                  ),
                ),

                TextButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver detalhes'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagem do produto
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: produto.imageUrl.isNotEmpty
                                        ? Image.asset(
                                      produto.imageUrl.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                    )
                                        : Image.network(
                                      'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Nome do produto
                                Text(
                                  produto.nome,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Preço do produto
                                Text(
                                  'R\$ ${produto.preco.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const Divider(height: 24),

                                // Descrição
                                Text(
                                  produto.descricao,
                                  style: const TextStyle(fontSize: 14),
                                ),

                                const SizedBox(height: 24),

                                // Botão de adicionar ao carrinho
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: const Text('Adicionar ao carrinho'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      textStyle: const TextStyle(fontSize: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      Provider.of<CarrinhoProvider>(
                                        context,
                                        listen: false,
                                      ).adicionar(produto, 1);

                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Produto adicionado ao carrinho!'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final produto = widget.produto;
  //
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.grey[100],
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         ClipRRect(
  //             borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
  //           child: AspectRatio(
  //             aspectRatio: 4 / 3,
  //             child: PageView.builder(
  //               controller: _pageController,
  //               itemCount: produto.imageUrl.length,
  //               itemBuilder: (context, index) {
  //                 final imageUrl = produto.imageUrl[index];
  //                 return _buildImage(imageUrl);
  //               },
  //             ),
  //           ),
  //         ),
  //
  //         // const SizedBox(height: 8),
  //
  //         Padding(
  //           padding: const EdgeInsets.all(8),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 produto.nome,
  //                 style: const TextStyle(fontWeight: FontWeight.bold),
  //                 maxLines: 2,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 'R\$ ${produto.preco.toStringAsFixed(2)}',
  //                 style: const TextStyle(color: Colors.green),
  //               ),
  //               const SizedBox(height: 8),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton.icon(
  //                   icon: const Icon(Icons.add_shopping_cart, size: 18),
  //                   label: const Text('Adicionar', style: TextStyle(fontSize: 14)),
  //                   style: ElevatedButton.styleFrom(
  //                     padding: const EdgeInsets.symmetric(vertical: 10),
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                 ),
  //                   onPressed: widget.onAddToCart,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  }

