import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/user.dart' as app_user;
import 'package:padariavinhos/services/auth_service.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';

class SignUpNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AuthNotifier _authNotifier;

  SignUpNotifier(this._authNotifier);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> signUp({
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
    _isLoading = true;
    notifyListeners();

    try {
      final newUser = await _authService.createUser(
        nome: nome,
        email: email,
        senha: senha,
        telefone: telefone,
        cep: cep,
        endereco: endereco,
        numeroEndereco: numeroEndereco,
        tipoResidencia: tipoResidencia,
        ramalApartamento: ramalApartamento,
        location: location,
      );

      await _authNotifier.setUser(newUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
