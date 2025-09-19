import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BannerCarousel extends StatefulWidget {
  final void Function(String produtoId) onBannerTap;

  const BannerCarousel({super.key, required this.onBannerTap});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final CollectionReference bannersRef =
  FirebaseFirestore.instance.collection('banners');

  final ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 250, // desliza 1 item (ajuste se quiser)
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 250,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // altura aumentada pra caber botões
      child: Stack(
        alignment: Alignment.center,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: bannersRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar banners.'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final banners = snapshot.data!.docs
                  .map((doc) => BannerModel.fromMap(
                  doc.data()! as Map<String, dynamic>, doc.id))
                  .toList();

              if (banners.isEmpty) {
                return const Center(child: Text('Nenhum banner disponível'));
              }

              return ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 48),
                itemCount: banners.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return _BannerItem(
                    banner: banner,
                    onTap: () {
                      if (banner.produtoId != null) {
                        widget.onBannerTap(banner.produtoId!);
                      }
                    },
                  );
                },
              );
            },
          ),
          // Botão Esquerda
          Positioned(
            left: 0,
            child: IconButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black45),
              ),
              onPressed: _scrollLeft,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
          // Botão Direita
          Positioned(
            right: 0,
            child: IconButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.black45),
              ),
              onPressed: _scrollRight,
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerItem extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onTap;

  const _BannerItem({required this.banner, required this.onTap});

  Future<String?> _getProdutoNome(String produtoId) async {
    final doc = await FirebaseFirestore.instance
        .collection('produtos')
        .doc(produtoId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      return data['nome'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            if (banner.produtoId != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: FutureBuilder<String?>(
                  future: _getProdutoNome(banner.produtoId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20,
                        width: 100,
                        child: LinearProgressIndicator(color: Colors.white),
                      );
                    }
                    final nome = snapshot.data ?? 'Produto';
                    return Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BannerModel {
  final String id;
  final String imageUrl;
  final String? produtoId;

  BannerModel({required this.id, required this.imageUrl, this.produtoId});

  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      produtoId: map['produtoId'],
    );
  }
}
