import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:collection/collection.dart';
import 'package:padariavinhos/pages/fazer_pedido/add_to_cart_sheet.dart';

class BannerFullScreenPage extends StatelessWidget {
  final String imageUrl;
  final String? produtoId;
  final List<Acompanhamento> acompanhamentos;

  const BannerFullScreenPage({
    super.key,
    required this.imageUrl,
    required this.produtoId,
    required this.acompanhamentos,
  });

  @override
  Widget build(BuildContext context) {
    final productsNotifier = context.read<ProductsNotifier>();

    final produto = productsNotifier.produtos
        .firstWhereOrNull((p) => p.id == produtoId);

    final acompanhamentosDoProduto = produto == null
        ? <Acompanhamento>[]
        : acompanhamentos
        .where((a) => produto.acompanhamentosIds.contains(a.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// IMAGEM EM TELA CHEIA
          Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              child: Image.network(imageUrl),
            ),
          ),

          /// BOTÃO FECHAR
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// BOTÃO "VER PRODUTO" NO TOPO
          if (produto != null)
            Positioned(
              top: 40,
              right: 16,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  showAddToCartSheet(
                    context,
                    produto,
                    acompanhamentosDoProduto,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Ver Produto",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
