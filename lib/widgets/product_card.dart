import 'package:flutter/material.dart';
import '../models/produto.dart';
import 'dart:async';

class ProductCard extends StatefulWidget {
  final Produto produto;
  final VoidCallback onAddToCart;
  final VoidCallback? onViewDetails;

  const ProductCard({
    Key? key,
    required this.produto,
    required this.onAddToCart,
    this.onViewDetails,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

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

  Widget _buildImage(String imageUrl, {double? borderRadius = 12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: GestureDetector(
        onTap: () => _abrirVisualizadorImagens(context, widget.produto.imageUrl, _currentPage),
        child: Image.network(
          imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/400',
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _abrirVisualizadorImagens(BuildContext context, List<String> imagens, int paginaInicial) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VisualizadorImagensFullScreen(
          imagens: imagens,
          paginaInicial: paginaInicial,
        ),
      ),
    );
  }

  void _abrirDetalhesProduto(BuildContext context) {
    final produto = widget.produto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    produto.imageUrl.isNotEmpty ? produto.imageUrl[0] : '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  produto.nome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  produto.descricao ?? 'Sem descrição',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;
    final larguraTela = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem em destaque com swipe e clique para fullscreen
              AspectRatio(
                aspectRatio: 4 / 3,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: produto.imageUrl.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) =>
                      _buildImage(produto.imageUrl[index], borderRadius: 16),
                ),
              ),

              // Indicador de página embaixo da imagem
              if (produto.imageUrl.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(produto.imageUrl.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 12 : 8,
                        height: _currentPage == index ? 12 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.green : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: larguraTela * 0.04,
                  vertical: larguraTela * 0.035,
                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.nome,
                        style: TextStyle(
                          fontSize: larguraTela * 0.05,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: larguraTela * 0.01),
                      Text(
                        'R\$ ${produto.preco.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: larguraTela * 0.045,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: larguraTela * 0.03),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart, size: 20),
                          label: const Text('Adicionar'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: larguraTela * 0.038),
                            textStyle: TextStyle(fontSize: larguraTela * 0.048),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: widget.onAddToCart,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.info_outline),
                        label: Text(
                          'Ver detalhes',
                          style: TextStyle(fontSize: larguraTela * 0.04),
                        ),
                        onPressed: () => _abrirDetalhesProduto(context),
                      ),
                    ],
                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VisualizadorImagensFullScreen extends StatefulWidget {
  final List<String> imagens;
  final int paginaInicial;

  const _VisualizadorImagensFullScreen({
    Key? key,
    required this.imagens,
    required this.paginaInicial,
  }) : super(key: key);

  @override
  State<_VisualizadorImagensFullScreen> createState() => _VisualizadorImagensFullScreenState();
}

class _VisualizadorImagensFullScreenState extends State<_VisualizadorImagensFullScreen> {
  late final PageController _pageController;
  late int _paginaAtual;

  @override
  void initState() {
    super.initState();
    _paginaAtual = widget.paginaInicial;
    _pageController = PageController(initialPage: _paginaAtual);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('${_paginaAtual + 1} / ${widget.imagens.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagens.length,
        onPageChanged: (index) {
          setState(() {
            _paginaAtual = index;
          });
        },
        itemBuilder: (context, index) {
          final imageUrl = widget.imagens[index];
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image_outlined, size: 80, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
