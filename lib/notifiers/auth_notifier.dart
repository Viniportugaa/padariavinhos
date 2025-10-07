import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:padariavinhos/models/user.dart' as app_user;
import 'package:padariavinhos/services/auth_service.dart';
import 'package:padariavinhos/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/services/entrega_service.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService();

  app_user.User? _user;
  app_user.User? get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  String? _role;
  String? get role => _role;

  String? systemMessage;
  bool splashFinished = false;

  StreamSubscription<fb.User?>? _authSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  AuthNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _checkConnectivity();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOnline != _isOnline) notifyListeners();
    });

    _authSub = _authService.authStateChanges.listen((fbUser) async {
      _isLoading = true;
      notifyListeners();

      if (!_isOnline) {
        systemMessage = "Sem conexão com a internet";
        _isLoading = false;
        splashFinished = true;
        notifyListeners();
        return;
      }

      if (fbUser != null) {
        try {
          final loadedUser = await _authService.fetchUserData(fbUser.uid);
          if (loadedUser == null) {
            await logout();
            systemMessage = "Conta inválida. Faça login novamente.";
          } else {
            _user = loadedUser;
            _role = loadedUser.role;
            _isAuthenticated = true;

            await _authService.updateFcmToken(fbUser.uid);
          }
        } catch (e) {
          systemMessage = "Erro ao carregar usuário.";
          _user = null;
          _role = null;
          _isAuthenticated = false;
        }
      } else {
        _user = null;
        _role = null;
        _isAuthenticated = false;
      }

      _isLoading = false;
      splashFinished = true;
      notifyListeners();
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedUser = await _authService.loginWithEmail(email, password);
      if (loggedUser != null) {
        _user = loggedUser;
        _role = loggedUser.role;
        _isAuthenticated = true;
      }
    } catch (_) {
      systemMessage = "Erro no login. Verifique seus dados.";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUser(app_user.User user) async {
    _user = user;
    _role = user.role;
    _isAuthenticated = true;
    await _authService.updateFcmToken(user.uid);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}

    _isAuthenticated = false;
    _role = null;
    _user = null;
    notifyListeners();
  }

  Future<bool> atualizarUsuario(Map<String, dynamic> novosDados) async {
    if (_user == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update(novosDados);

      _user = _user!.copyWith(
        nome: novosDados['nome'] ?? _user!.nome,
        endereco: novosDados['endereco'] ?? _user!.endereco,
        numeroEndereco: novosDados['numeroEndereco'] ?? _user!.numeroEndereco,
        tipoResidencia: novosDados['tipoResidencia'] ?? _user!.tipoResidencia,
        ramalApartamento: novosDados['ramalApartamento'] ?? _user!.ramalApartamento,
        telefone: novosDados['telefone'] ?? _user!.telefone,
        cep: novosDados['cep'] ?? _user!.cep,
        location: novosDados['location'] ?? _user!.location,
      );

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> atualizarEndereco({
    required String cep,
    required String endereco,
    required String numero,
    required String tipoResidencia,
    String? ramal,
  }) async {
    if (_user == null) return false;

    try {
      final resultado = await EntregaService.verificarEndereco(cep);

      GeoPoint? location;
      if (resultado['lat'] != null && resultado['lng'] != null) {
        location = GeoPoint(resultado['lat'], resultado['lng']);
      }

      return await atualizarUsuario({
        'cep': cep,
        'endereco': endereco,
        'numeroEndereco': numero,
        'tipoResidencia': tipoResidencia,
        'ramalApartamento': ramal,
        if (location != null) 'location': location,
      });
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _isOnline = result != ConnectivityResult.none;
    } catch (_) {
      _isOnline = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
