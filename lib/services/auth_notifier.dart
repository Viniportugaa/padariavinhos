import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:padariavinhos/models/user.dart' as app_user;

class AuthNotifier extends ChangeNotifier {

  app_user.User? _user;
  app_user.User? get user => _user;

  late final StreamSubscription<User?> _authSub;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  bool splashFinished = false;
  bool usuarioDesconectado = false;

  bool _isAuthenticated = false;
  bool _isOnline = true;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _role;

  final ValueNotifier<String?> systemMessage = ValueNotifier(null);

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnline => _isOnline;
  String? get role => _role;

  AuthNotifier() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await _checkConnectivity();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      // results agora é uma List<ConnectivityResult>
      _isOnline = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.ethernet);

      notifyListeners();
    });


    await _loadAuthState();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!_isOnline) {
        notifyListeners();
        return;
      }

      if (user != null) {
        await user.reload();
        final atual = FirebaseAuth.instance.currentUser;

        if (atual == null) {
          await logout();
          usuarioDesconectado = true;
          systemMessage.value = 'Sua conta foi removida. Faça login novamente.';
        } else {
          await _persistLoginState(true);
          _isAuthenticated = true;
          await _loadUserData(user.uid);
        }
      } else {
        await _persistLoginState(false);
        _isAuthenticated = false;
        _role = null;
        _user = null;
      }

      _isLoading = false;
      notifyListeners();
    });

    Timer(const Duration(seconds: 3), () {
      splashFinished = true;
      notifyListeners();
    });
  }

Future<void> _checkConnectivity() async {
  final results = await Connectivity().checkConnectivity();
    _isOnline = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet);

  notifyListeners();
}

  Future<void> validateSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (FirebaseAuth.instance.currentUser == null) {
        await logout();
        systemMessage.value = 'Sessão expirada. Faça login novamente.';
      }
    }
  }

  Future<void> login() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isAuthenticated = true;
      await _persistLoginState(true);
      await _loadUserData(user.uid);
      notifyListeners();
    }
  }
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _isAuthenticated = false;
    _role = null;
    await _persistLoginState(false);
    notifyListeners();
  }

  Future<void> _persistLoginState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', value);
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
  }

  Future<void> _loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    print('🔍 Tentando carregar dados do Firestore para uid: $uid');

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _user = app_user.User.fromMap(data); // ou seu método equivalente
        _role = _user?.role;
      } else {
        _user = null;
        _role = null;
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
      _user = null;
      _role = null;
    }
    _isLoading = false;
    notifyListeners();
  }



  void markSplashFinished() {
    splashFinished = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _connectivitySub.cancel();
    systemMessage.dispose();
    super.dispose();
  }
}