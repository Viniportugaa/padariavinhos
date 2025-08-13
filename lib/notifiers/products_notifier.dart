// lib/notifiers/products_notifier.dart

import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/product_service.dart';
import 'dart:async';


class ProductsNotifier extends ChangeNotifier {
  final _service = ProductService();
  List<Produto> produtos = [];
  bool loading = true;
  bool _loaded = false;

  String? categoriaSelecionada;

  // Lista fixa de categorias
  final List<String> categoriasFixas = [
    'Festividade', 'Bolos', 'Doce', 'Lanches',
    'Pratos', 'Paes', 'Refrigerante', 'Salgados', 'Sucos',
  ];

  StreamSubscription? _subscription;

  void startListening() {
    loading = true;
    notifyListeners();

    _subscription = _service
        .streamProdutosDisponiveis()
        .listen((produtosNovos) {
      produtos = produtosNovos;
      loading = false;
      notifyListeners();
    }, onError: (error) {
      // trate o erro como preferir
      loading = false;
      notifyListeners();
    });
  }

    @override
    void dispose() {
      _subscription?.cancel();
      super.dispose();
    }

    List<Produto> get produtosFiltrados {
      if (categoriaSelecionada == null) return produtos;
      final filtro = categoriaSelecionada!.trim().toLowerCase();
      return produtos.where((p) => p.category.trim().toLowerCase() == filtro).toList();
    }

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

    void filtrarPorCategoria(String? categoria) {
      categoriaSelecionada = categoria;
      notifyListeners();
    }

    void limparFiltroCategoria() {
      categoriaSelecionada = null;
      notifyListeners();
    }
  }