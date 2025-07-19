// lib/notifiers/products_notifier.dart

import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/product_service.dart';



class ProductsNotifier extends ChangeNotifier {
  final _service = ProductService();
  List<Produto> produtos = [];
  bool loading = false;
  bool _loaded = false;

  String? categoriaSelecionada;

  // Lista fixa de categorias
  final List<String> categoriasFixas = [
    'Festividade', 'Bolos', 'Doce', 'Lanches',
    'Pratos', 'Paes', 'Refrigerante', 'Salgados', 'Sucos',
  ];



  Future<void> load() async {
    if (_loaded) return;
    print('Iniciando carregamento de produtos...');
    loading = true;
    notifyListeners();

    produtos = await _service.fetchProdutos();
    print('Produtos carregados: ${produtos.length}');

    loading = false;
    _loaded = true;
    notifyListeners();
  }
  List<Produto> get produtosFiltrados {
    if (categoriaSelecionada == null) return produtos;
    return produtos.where((p) => p.category == categoriaSelecionada).toList();
  }

  // Categorias únicas dinâmicas + fixas
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

  // Filtro por categoria
  void filtrarPorCategoria(String categoria) {
    categoriaSelecionada = categoria;
    notifyListeners();
  }

  // Limpar filtro
  void limparFiltroCategoria() {
    categoriaSelecionada = null;
    notifyListeners();
  }


}