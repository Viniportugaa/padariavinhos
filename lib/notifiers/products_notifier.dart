// lib/notifiers/products_notifier.dart

import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/product_service.dart';
import '../provider/favoritos_provider.dart';
import 'dart:async';

class ProductsNotifier extends ChangeNotifier {
  final _service = ProductService();

  List<Produto> produtos = [];
  bool loading = true;

  String? categoriaSelecionada;
  StreamSubscription? _subscription;

  final List<String> categoriasFixas = [
    'Pratos', 'Bolos', 'Doce', 'Lanches',
    'Festividades', 'Paes', 'Refrigerante', 'Salgados', 'Sucos',
  ];

  /// Inicia a escuta de produtos disponíveis
  void startListening() {
    // Adiar o notifyListeners inicial para evitar erro durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loading = true;
      notifyListeners();
    });

    _subscription = _service.streamProdutosDisponiveis().listen(
          (produtosNovos) {
        produtos = produtosNovos;
        loading = false;
        notifyListeners();
      },
      onError: (error) {
        loading = false;
        notifyListeners();
      },
    );
  }

  /// Filtra produtos pelo favorito ou categoria
  List<Produto> produtosFiltrados(FavoritosProvider favoritosProvider) {
    if (categoriaSelecionada == null) return produtos;

    final filtro = categoriaSelecionada!.trim().toLowerCase();

    if (filtro == 'favoritos') {
      return produtos.where((p) => favoritosProvider.isFavorito(p.id)).toList();
    }

    return produtos
        .where((p) => p.category.trim().toLowerCase() == filtro)
        .toList();
  }

  /// Retorna todas as categorias únicas, mantendo as fixas primeiro
  List<String> get categoriasUnicas {
    final setCategorias = <String>{};
    for (final produto in produtos) {
      if (produto.category.isNotEmpty) {
        setCategorias.add(produto.category);
      }
    }

    return [
      ...categoriasFixas,
      ...setCategorias.where((c) => !categoriasFixas.contains(c)),
    ];
  }

  /// Aplica filtro por categoria
  void filtrarPorCategoria(String? categoria) {
    categoriaSelecionada = categoria;
    notifyListeners();
  }

  /// Limpa o filtro
  void limparFiltroCategoria() {
    categoriaSelecionada = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
