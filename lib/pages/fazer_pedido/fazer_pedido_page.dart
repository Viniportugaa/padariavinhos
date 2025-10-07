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
      double newOpacity = (1 - (offset / 200)).clamp(0.0, 1.0);
      double newHeight = (180 - offset).clamp(_minBannerHeight, 180).toDouble();
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
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFFAF0), Color(0xFFF5F5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                if (_bannerHeight > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _bannerHeight,
                    child: AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: BannerSection(acompanhamentos: acompanhamentos),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_opacity > 0)
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CategoriasSection(mostrar: mostrarCategorias),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                ProdutoSearchBar(
                  onChanged: (valor) => setState(() => filtroNome = valor),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
