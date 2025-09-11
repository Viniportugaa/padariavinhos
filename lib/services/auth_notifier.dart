import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:padariavinhos/models/user.dart' as app_user;
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:google_sign_in/google_sign_in.dart';


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

  String? _phoneVerificationId;

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


  Future<String?> registerWithEmail(String email, String password, String nome) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.sendEmailVerification();

      // Cria documento no Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'nome': nome,
        'role': 'cliente',
        'fcmToken': await FirebaseMessaging.instance.getToken(),
        'emailVerified': cred.user!.emailVerified,
      });

      return null; // sucesso
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!cred.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        return 'E-mail não verificado. Verifique sua caixa de entrada.';
      }

      await login(); // já carrega user + fcm token
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro inesperado: $e';
    }
  }

  // Future<String?> loginWithGoogle() async {
  //   try {
  //     final googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) return 'Login cancelado pelo usuário.';
  //
  //     final googleAuth = await googleUser.authentication;
  //
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
  //
  //     // Cria/atualiza usuário no Firestore
  //     final userDoc = FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid);
  //     final snap = await userDoc.get();
  //
  //     if (!snap.exists) {
  //       await userDoc.set({
  //         'uid': userCred.user!.uid,
  //         'email': userCred.user!.email,
  //         'nome': userCred.user!.displayName ?? '',
  //         'role': 'cliente',
  //         'fcmToken': await FirebaseMessaging.instance.getToken(),
  //         'emailVerified': true, // Google já vem verificado
  //       });
  //     } else {
  //       await userDoc.update({
  //         'fcmToken': await FirebaseMessaging.instance.getToken(),
  //       });
  //     }
  //
  //     await login();
  //     return null;
  //   } catch (e) {
  //     return 'Erro no login com Google: $e';
  //   }
  // }

  Future<String?> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // ✅ Verificação de email
  Future<bool> checkEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
    } catch (e) {
      print("❌ Erro ao verificar email: $e");
    }
    return false;
  }

  // 📱 Inicia verificação por telefone
  Future<void> startPhoneVerification(
      String phoneNumber, {
        required void Function(String verificationId) codeSent,
        required void Function(String error) onError,
      }) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await login();
        },
        verificationFailed: (FirebaseAuthException e) {
          print("❌ Erro na verificação de telefone: ${e.message}");
          onError(e.message ?? "Erro desconhecido");
        },
        codeSent: (String verificationId, int? resendToken) {
          _phoneVerificationId = verificationId;
          print("📲 Código enviado para $phoneNumber");
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _phoneVerificationId = verificationId;
          print("⌛ Timeout para verificação: $verificationId");
        },
      );
    } catch (e) {
      print("❌ Erro no startPhoneVerification: $e");
      onError(e.toString());
    }
  }

  // 🔑 Confirma SMS
  Future<bool> confirmPhoneCode(String smsCode) async {
    try {
      if (_phoneVerificationId == null) {
        print("❌ Nenhuma verificação iniciada.");
        return false;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _phoneVerificationId!,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await login();
      return true;
    } catch (e) {
      print("❌ Erro ao confirmar SMS: $e");
      return false;
    }
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