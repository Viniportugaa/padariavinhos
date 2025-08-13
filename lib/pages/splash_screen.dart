import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/main.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/widgets/auth_panel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
    if (!mounted) return;

    Provider.of<AuthNotifier>(context, listen: false).markSplashFinished();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
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
            const SizedBox(height: 40),
            const AuthStatusPanel(), // ✅ Painel de status inserido aqui
          ],
        ),
      ),
    );
  }
}