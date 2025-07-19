import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padariavinhos/pages/menuinicial_page.dart';
import 'package:padariavinhos/pages/login_page.dart';
import 'package:padariavinhos/router.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    print('SplashScreen: initState chamado'); // PRINT
    _startAnimation();
    _finishSplashAfterDelay();
  }

  void _startAnimation() {
    // Inicia o fade depois de um pequeno delay
    Future.delayed(const Duration(milliseconds: 300), () {
      print('SplashScreen: começando animação'); // PRINT
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  Future<void> _finishSplashAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    print('SplashScreen: delay finalizado'); // PRINT
    if (mounted) {
      context.go('/menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (authNotifier.usuarioDesconectado) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Sua conta foi removida. Faça login novamente.'),
    //         backgroundColor: Colors.redAccent,
    //       ),
    //     );
    //     authNotifier.usuarioDesconectado = false;
    //   });
    // }
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green,
              Colors.black,
              Colors.black,
              Colors.red,
            ],
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            child: Image.asset(
              'assets/LogoPadariaVinhosBranco.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
