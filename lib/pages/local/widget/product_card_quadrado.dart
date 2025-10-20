import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/services/firebase_storage_service.dart';
import 'package:padariavinhos/pages/local/add_to_cart_local_sheet.dart'; // Import necessário para chamar o sheet
import 'package:padariavinhos/models/acompanhamento.dart';

class ProductCardQuadrado extends StatefulWidget {
  final Produto produto;
  final List<Acompanhamento>? acompanhamentos;

  const ProductCardQuadrado({
    super.key,
    required this.produto,
    this.acompanhamentos,
  });

  @override
  State<ProductCardQuadrado> createState() => _ProductCardQuadradoState();
}

class _ProductCardQuadradoState extends State<ProductCardQuadrado> {
  String? imageUrl;
  bool isLoadingImage = true;
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      if (widget.produto.imageUrl.isNotEmpty) {
        final raw = widget.produto.imageUrl.first;
        if (raw.startsWith('http')) {
          setState(() {
            imageUrl = raw;
            isLoadingImage = false;
          });
        } else {
          final url = await getProdutoImageUrl(raw);
          if (mounted) {
            setState(() {
              imageUrl = url;
              isLoadingImage = false;
            });
          }
        }
      } else {
        setState(() => isLoadingImage = false);
      }
    } catch (e) {
      debugPrint('Erro ao carregar imagem do produto: $e');
      if (mounted) setState(() => isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          showAddToCartSheetLocal(
            context,
            widget.produto,
            widget.acompanhamentos ?? [],
          );
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          scale: isHovered ? 1.04 : 1.0,
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 🖼️ Imagem principal
                Hero(
                  tag: 'produto_${widget.produto.id}',
                  child: isLoadingImage
                      ? Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.brown),
                    ),
                  )
                      : imageUrl != null
                      ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                      : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.brown,
                    ),
                  ),
                ),

                // 🔸 Gradiente escuro no rodapé
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black54,
                      ],
                    ),
                  ),
                ),

                // 🔸 Nome + preço sobrepostos
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produto.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                      ),
                      Text(
                        'R\$ ${widget.produto.preco.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ✨ Efeito de brilho leve ao hover
                AnimatedOpacity(
                  opacity: isHovered ? 0.12 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
