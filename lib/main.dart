import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
// Notifiers
import 'notifiers/products_notifier.dart';
import 'provider/carrinhos_provider.dart';
import 'notifiers/auth_notifier.dart';
import 'notifiers/config_notifier.dart';
import 'router.dart';
import 'package:padariavinhos/provider/pedido_provider.dart';
import 'package:padariavinhos/provider/favoritos_provider.dart';

/// 🔹 Handler para notificações em background/terminated
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📩 Mensagem recebida em segundo plano: ${message.notification?.title}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'pedidos_channel', // ID do canal
  'Notificações de Pedidos', // Nome
  description: 'Notificações importantes de pedidos',
  importance: Importance.high,
  playSound: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🟡 Rodando em: ${kIsWeb ? "Web" : Platform.operatingSystem}");

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("✅ Firebase inicializado");

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
    print("✅ App Check ativado");


  // Configura handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializa flutter_local_notifications
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductsNotifier()),
        ChangeNotifierProvider(create: (_) => CarrinhoProvider()),
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => ConfigNotifier()..startListening()),
        ChangeNotifierProvider(create: (_) => PedidoProvider()),
        ChangeNotifierProvider(create: (_) => FavoritosProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    // Solicita permissão para notificações (iOS/Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("🔔 Permissão de notificações: ${settings.authorizationStatus}");

    // Token inicial
    await _saveDeviceToken();

    // Atualização automática do token
    _messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 Token FCM atualizado: $newToken");
      await _saveDeviceToken(newToken: newToken);
    });

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📢 Mensagem em foreground: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // Clique na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final pedidoId = message.data['pedidoId'];
      if (pedidoId != null) {
        context.push("/pedido/$pedidoId"); // ou: PedidoPage(pedidoId: pedidoId)
      }
    });

    // Mensagem recebida com app fechado
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("📦 App aberto via notificação: ${initialMessage.data}");
    }
  }

  /// Salva token no Firestore
  Future<void> _saveDeviceToken({String? newToken}) async {
    final token = newToken ?? await _messaging.getToken();
    print("📲 Device FCM Token: $token");
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"fcmToken": token});
    }
  }

  /// Exibe notificação local (foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null && !kIsWeb) {
      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );
      final platformDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data['pedidoId'] ?? '',
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final router = createRouter(context.read<AuthNotifier>());
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,


        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}