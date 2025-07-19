import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;
  bool splashFinished = false;
  bool usuarioDesconectado = false;


  AuthNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await user.reload(); // força verificação com backend
        if (FirebaseAuth.instance.currentUser == null) {
          // usuário foi deletado remotamente, então fazemos logout
          await FirebaseAuth.instance.signOut();
          usuarioDesconectado = true;

        }
      }
      notifyListeners(); // avisa o GoRouter para reavaliar o redirect
    });

    Timer(const Duration(seconds: 3), () {
      splashFinished = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}