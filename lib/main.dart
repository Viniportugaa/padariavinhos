import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/router.dart';
import 'firebase_options.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// Notifiers
import 'notifiers/products_notifier.dart';



import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🟡 Rodando em: ${kIsWeb ? "Web" : Platform.operatingSystem}");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase inicializado com sucesso");
  } catch (e, stack) {
    print("❌ Erro ao inicializar Firebase: $e");
    print("Stacktrace: $stack");
  }
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
      print("✅ App Check ativado");
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProductsNotifier()),
          ChangeNotifierProvider(create: (_) => CarrinhoProvider()),
          ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ],
        child: const MyApp(),
      ),
    );
  }


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("App started");
    final router = createRouter(context.read<AuthNotifier>());
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
    ),

    );
  }
}