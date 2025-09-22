import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/provider/favoritos_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:padariavinhos/services/firebase_storage_service.dart'; // função getProdutoImageUrl

class ProductCardHorizontal extends StatefulWidget {
  final Produto produto;
  final VoidCallback onAddToCart;
  final VoidCallback? onViewDetails;
  final Color cardColor;

  const ProductCardHorizontal({
    super.key,
    required this.produto,
    required this.onAddToCart,
    this.onViewDetails,
    this.cardColor = Colors.white,
  });

  @override
  State<ProductCardHorizontal> createState() => _ProductCardHorizontalState();
}

class _ProductCardHorizontalState extends State<ProductCardHorizontal> {
  String? imageUrl;
  bool isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.produto.imageUrl.isNotEmpty) {
      final raw = widget.produto.imageUrl.first;

      // Se já for uma URL completa (começa com https://), usa direto
      if (raw.startsWith('http')) {
        setState(() {
          imageUrl = raw;
          isLoadingImage = false;
        });
      } else {
        // Caso seja apenas o path salvo no Firestore, busca o download URL
        final url = await getProdutoImageUrl(raw);
        if (mounted) {
          setState(() {
            imageUrl = url;
            isLoadingImage = false;
          });
        }
      }
    } else {
      setState(() {
        isLoadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritosProvider = context.watch<FavoritosProvider>();
    final isFavorito = favoritosProvider.isFavorito(widget.produto.id);

    return GestureDetector(
      onTap: widget.onViewDetails,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: widget.onViewDetails,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isLoadingImage
                              ? Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          )
                              : imageUrl != null
                              ? Image.network(
                            imageUrl!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                width: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          )
                              : Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                      if (widget.produto.vendidoPorPeso)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Por Peso',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          widget.produto.descricao ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.produto.vendidoPorPeso
                              ? 'R\$ ${widget.produto.preco.toStringAsFixed(2)} (estimado)'
                              : 'R\$ ${widget.produto.preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => context.read<FavoritosProvider>().toggleFavorito(widget.produto),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Icon(isFavorito ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 22),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.orangeAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onAddToCart,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
