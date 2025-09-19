import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/widgets/banner_carousel.dart';
import 'package:padariavinhos/pages/product_detalhe_page.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/pages/fazer_pedido/add_to_cart_sheet.dart';
import 'package:collection/collection.dart';


class BannerSection extends StatefulWidget {
  final List<Acompanhamento> acompanhamentos;
  const BannerSection({super.key, required this.acompanhamentos});

  @override
  State<BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  final ScrollController _scrollController = ScrollController();
  final double _maxBannerHeight = 180;
  final double _minBannerHeight = 0;
  double _currentBannerHeight = 180;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_atualizarAlturaBanner);
  }

  void _atualizarAlturaBanner() {
    final offset = _scrollController.offset;
    final newHeight = (_maxBannerHeight - offset).clamp(_minBannerHeight, _maxBannerHeight);
    if (newHeight != _currentBannerHeight) {
      setState(() => _currentBannerHeight = newHeight);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_atualizarAlturaBanner);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BannerCarousel(onBannerTap: (produtoId) {
        // Pega o ProductsNotifier
        final productsNotifier = context.read<ProductsNotifier>();

        // Busca o produto pelo ID
        final produto = productsNotifier.produtos
            .firstWhereOrNull((p) => p.id == produtoId);


        if (produto != null) {
          // Filtra os acompanhamentos do produto
          final acompanhamentosDoProduto = widget.acompanhamentos
              .where((a) => produto.acompanhamentosIds.contains(a.id))
              .toList();


          // Abre o modal de adicionar ao carrinho
          showAddToCartSheet(context, produto, acompanhamentosDoProduto);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto não encontrado.')),
          );
        }
      });
  }
}
