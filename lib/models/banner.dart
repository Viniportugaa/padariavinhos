class BannerModel {
  final String id;
  final String imageUrl;
  final String? produtoId;
  final List<String> diasVisiveis; // 👈 NOVO

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.produtoId,
    required this.diasVisiveis,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      produtoId: map['produtoId'],
      diasVisiveis: List<String>.from(map['diasVisiveis'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'produtoId': produtoId,
      'diasVisiveis': diasVisiveis,
    };
  }
}
