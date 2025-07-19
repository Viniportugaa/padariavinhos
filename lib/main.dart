import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/router.dart';
import 'firebase_options.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';

// Notifiers
import 'notifiers/products_notifier.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  //final authStream = FirebaseAuth.instance.authStateChanges();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductsNotifier()),
        ChangeNotifierProvider(create: (context)=> AuthService()),
        ChangeNotifierProvider(create: (_) => CarrinhoProvider()),

      ],
      child: MyApp()
  )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("App started");
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