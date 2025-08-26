import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:padariavinhos/models/user.dart' as app_user;
import 'package:firebase_messaging/firebase_messaging.dart';


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
  String? get role => _role;

  String? systemMessage;

  Timer? _splashTimer;

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnline => _isOnline;

  AuthNotifier() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await _checkConnectivity();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _isOnline = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.ethernet);

      notifyListeners();
    });

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
          systemMessage = 'Sua conta foi removida. Faça login novamente.';
        } else {
          _isAuthenticated = true;
          await _loadUserData(user.uid);
          await _requestNotificationPermission();
          await _updateFcmToken(user.uid);
        }
      } else {
        _isAuthenticated = false;
        _role = null;
        _user = null;
      }

      _isLoading = false;
      notifyListeners();
    });

    _splashTimer = Timer(const Duration(seconds: 3), () {
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
        systemMessage = 'Sessão expirada. Faça login novamente.';
      }
    }
  }

  Future<void> login() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isAuthenticated = true;
      await _loadUserData(user.uid);
      await _requestNotificationPermission();
      await _updateFcmToken(user.uid);
      notifyListeners();
    }
  }
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _isAuthenticated = false;
    _role = null;
    _user = null;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    print('🔍 Tentando carregar dados do Firestore para uid: $uid');

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _user = app_user.User.fromMap(data);
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

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    print("🔔 Permissão de notificações: ${settings.authorizationStatus}");
  }

  Future<void> _updateFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
        print("✅ FCM Token atualizado no Firestore: $token");
      }
    } catch (e) {
      print("❌ Erro ao atualizar FCM Token: $e");
    }
  }

  void markSplashFinished() {
    splashFinished = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _connectivitySub.cancel();
    _splashTimer?.cancel();
    super.dispose();
  }
}