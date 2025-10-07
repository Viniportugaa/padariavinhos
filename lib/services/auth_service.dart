import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/user.dart' as app_user;
import 'package:padariavinhos/services/entrega_service.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// 🔹 Stream de mudanças de autenticação (FirebaseAuth)
  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// 🔹 Buscar dados do usuário no Firestore
  Future<app_user.User?> fetchUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) return null;

    final user = app_user.User.fromMap(doc.data()!);

    // 🔹 Se localização inválida (0,0), tentar corrigir pelo CEP
    if (user.location.latitude == 0 && user.location.longitude == 0 && user.cep.isNotEmpty) {
      final coords = await EntregaService.verificarEndereco(user.cep);

      if (coords['valido'] == true && coords['lat'] != null && coords['lng'] != null) {
        final newLocation = GeoPoint(coords['lat'], coords['lng']);
        await _db.collection('users').doc(uid).update({
          'location': newLocation,
        });

        return user.copyWith(location: newLocation);
      }
    }

    return user;
  }

  /// 🔹 Login por e-mail e senha
  Future<app_user.User?> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final fbUser = credential.user;
    if (fbUser == null) throw Exception("Usuário não encontrado");

    await updateFcmToken(fbUser.uid);
    return await fetchUserData(fbUser.uid);
  }

  /// 🔹 Logout + remove token FCM do Firestore
  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    final token = await NotificationService.getFcmToken;

    if (uid != null && token != null) {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    }

    await _auth.signOut();
  }

  /// 🔹 Atualizar token FCM do usuário
  Future<void> updateFcmToken(String uid) async {
    final token = await NotificationService.getFcmToken(uid);
    if (token != null) {
      await _db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    }
  }

  /// 🔹 Criar usuário no Firebase Auth + Firestore
  Future<app_user.User> createUser({
    required String nome,
    required String email,
    required String senha,
    required String telefone,
    required String cep,
    required String endereco,
    required String numeroEndereco,
    required String tipoResidencia,
    String? ramalApartamento,
    GeoPoint? location,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha.trim(),
    );

    final uid = cred.user!.uid;
    final newUser = app_user.User(
      uid: uid,
      nome: nome,
      email: email,
      telefone: telefone,
      cep: cep,
      endereco: endereco,
      numeroEndereco: numeroEndereco,
      tipoResidencia: tipoResidencia,
      ramalApartamento: ramalApartamento,
      role: "cliente",
      createdAt: Timestamp.fromDate(DateTime.now()),
      location: location ?? const GeoPoint(0, 0),
    );

    await _db.collection('users').doc(uid).set(newUser.toMap());

    await updateFcmToken(uid);

    return newUser;
  }
}
