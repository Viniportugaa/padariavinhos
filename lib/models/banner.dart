class BannerModel {
  final String id;
  final String imageUrl;
  final String? produtoId; // ID do produto vinculado

  BannerModel({required this.id, required this.imageUrl, this.produtoId});

  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      produtoId: map['produtoId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'produtoId': produtoId,
    };
  }
}
