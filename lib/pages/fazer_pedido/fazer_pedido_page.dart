import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import 'package:padariavinhos/helpers/aberto_check.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/provider/favoritos_provider.dart';
import 'package:padariavinhos/models/acompanhamento.dart';

import 'sections/banner_section.dart';
import 'sections/produto_search_bar.dart';
import 'sections/categorias_section.dart';
import 'sections/produtos_section.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class FazerPedidoPage extends StatefulWidget {
  const FazerPedidoPage({super.key});

  @override
  State<FazerPedidoPage> createState() => _FazerPedidoPageState();
}

class _FazerPedidoPageState extends State<FazerPedidoPage> {
  String filtroNome = '';
  bool mostrarCategorias = true;
  List<Acompanhamento> acompanhamentos = [];

  final ScrollController _scrollController = ScrollController();

  double _opacity = 1.0;
  double _bannerHeight = 180;
  final double _minBannerHeight = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<ConfigNotifier>().startListening();
    context.read<ProductsNotifier>().startListening();
    _carregarAcompanhamentos();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      // Opacidade diminui até sumir
      double newOpacity = (1 - (offset / 200)).clamp(0.0, 1.0);

      // Banner encolhe suavemente até o mínimo
      double newHeight =
      (180 - offset).clamp(_minBannerHeight, 180).toDouble();

      if (newOpacity != _opacity || newHeight != _bannerHeight) {
        setState(() {
          _opacity = newOpacity;
          _bannerHeight = newHeight;
        });
      }
    });
  }

  Future<void> _carregarAcompanhamentos() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('acompanhamentos').get();
      setState(() {
        acompanhamentos = snapshot.docs
            .map((doc) => Acompanhamento.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar acompanhamentos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar acompanhamentos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbertoChecker(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_bannerHeight > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _bannerHeight,
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 200),
                    child: BannerSection(acompanhamentos: acompanhamentos),
                  ),
                ),
              const SizedBox(height: 12),
              if (_opacity > 0)
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 200),
                  child: CategoriasSection(mostrar: mostrarCategorias),
                ),
              const SizedBox(height: 6),

              ProdutoSearchBar(
                onChanged: (valor) => setState(() => filtroNome = valor),
              ),

              const SizedBox(height: 12),

              // Lista de produtos
              Expanded(
                child: Consumer2<ProductsNotifier, FavoritosProvider>(
                  builder: (context, productsNotifier, favoritosProvider, _) {
                    return ProdutosSection(
                      filtroNome: filtroNome,
                      acompanhamentos: acompanhamentos,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
