import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/produto.dart';

class FavoritosProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  List<Produto> _favoritos = [];
  List<Produto> get favoritos => _favoritos;

  FavoritosProvider() {
    _listenToFavoritos();
  }

  void _listenToFavoritos() {
    _db.collection('users').doc(uid).collection('favoritos').snapshots().listen(
          (snapshot) {
        _favoritos =
            snapshot.docs.map((doc) => Produto.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      },
    );
  }

  Future<void> toggleFavorito(Produto produto) async {
    final docRef = _db.collection('users').doc(uid).collection('favoritos').doc(produto.id);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set(produto.toMap());
    }
  }

  bool isFavorito(String produtoId) {
    return _favoritos.any((p) => p.id == produtoId);
  }
}
