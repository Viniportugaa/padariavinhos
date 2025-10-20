import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
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
import 'package:flutter/services.dart';

// Notifiers / Providers (mantive suas imports)
import 'notifiers/products_notifier.dart';
import 'package:padariavinhos/pages/signup/signup_notifier.dart';
import 'provider/carrinhos_provider.dart';
import 'notifiers/auth_notifier.dart';
import 'notifiers/config_notifier.dart';
import 'router.dart';
import 'package:padariavinhos/provider/pedido_provider.dart';
import 'package:padariavinhos/provider/favoritos_provider.dart';
import 'package:padariavinhos/pages/local/provider/pedido_local_provider.dart';

/// Background handler (quando app está em segundo plano / terminated)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("📩 Mensagem recebida (background): ${message.messageId} / data: ${message.data}");
  // Aqui você pode salvar eventos simples em DB ou disparar lógica server-side
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

  debugPrint("🟡 Plataforma detectada: ${kIsWeb ? "Web" : Platform.operatingSystem}");

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("✅ Firebase inicializado");

  // App Check (em produção troque provider para o recomendado)
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, // trocar em produção (playIntegrity/safetyNet)
    );
    // Criar canal Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  debugPrint("✅ AppCheck/LocalNotifications configurados");

  // Registra handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializa flutter_local_notifications (Android + iOS)
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    onDidReceiveLocalNotification: (id, title, body, payload) async {
      // iOS < 10 handler (não muito usado atualmente)
    },
  );
  final InitializationSettings initSettings =
  InitializationSettings(android: androidSettings, iOS: iosSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings, onDidReceiveNotificationResponse: (response) {
    final payload = response.payload ?? '';
    if (payload.isNotEmpty) {
      // Ex.: payload = pedidoId
      // Não temos contexto aqui; manipularemos redirecionamento quando app voltar ao foreground
      debugPrint("Tapped local notification payload: $payload");
    }
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductsNotifier()),
        ChangeNotifierProvider(create: (_) => CarrinhoProvider()),
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => PedidoLocalProvider()),
        ChangeNotifierProvider(create: (context) {
          final authNotifier = context.read<AuthNotifier>();
          return SignUpNotifier(authNotifier);
        }),
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
  String? _pendingPayloadFromNotification;

  @override
  void initState() {
    super.initState();
    _setupFCM();
    _listenAuthChanges();
  }
  String? _cachedTokenForLater;

  void _listenAuthChanges() {
    fb.FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final token = _cachedTokenForLater ?? await _messaging.getToken();
        if (token != null) {
          await _saveDeviceToken(uid: user.uid, token: token);
          _cachedTokenForLater = null;
        }
      }
    });
  }

  Future<void> _setupFCM() async {
    try {
      if (kIsWeb) {
        debugPrint("🌐 Web: obtendo token via getToken()");
        final token = await _messaging.getToken(vapidKey: null);
        debugPrint("📲 Web token: $token");
        final user = fb.FirebaseAuth.instance.currentUser;
        if (token != null) {
          if (user != null) {
            await _saveDeviceToken(uid: user.uid, token: token);
          } else {
            _cachedTokenForLater = token;
          }
        }
      } else {
        // MOBILE (iOS/Android)
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint("🔔 Permissão: ${settings.authorizationStatus}");

        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint("⚠️ O usuário negou permissões de notificação");
        }

        final token = await _messaging.getToken();
        debugPrint("📲 Device token: $token");
        final user = fb.FirebaseAuth.instance.currentUser;
        if (token != null) {
          if (user != null) {
            await _saveDeviceToken(uid: user.uid, token: token);
          } else {
            _cachedTokenForLater = token;
          }
        }

        _messaging.onTokenRefresh.listen((newToken) async {
          debugPrint("🔄 Token atualizado: $newToken");
          final user = fb.FirebaseAuth.instance.currentUser;
          if (user != null) {
            await _saveDeviceToken(uid: user.uid, token: newToken);
          } else {
            _cachedTokenForLater = newToken;
          }
        });
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("📢 onMessage: ${message.notification?.title} / ${message.data}");
        _showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("➡️ onMessageOpenedApp: ${message.data}");
        _handleMessageNavigation(message.data);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint("📦 getInitialMessage: ${initialMessage.data}");
        _pendingPayloadFromNotification = initialMessage.data['pedidoId']?.toString();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pendingPayloadFromNotification != null && mounted) {
            _navigateToPedidoId(_pendingPayloadFromNotification!);
            _pendingPayloadFromNotification = null;
          }
        });
      }
    } catch (e, st) {
      debugPrint("Erro no setup FCM: $e\n$st");
    }
  }

  Future<void> _saveDeviceToken({required String uid, required String token}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint("✅ Token salvo (users/$uid)");
    } catch (e) {
      debugPrint("Erro salvando token: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails();

    final platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final payload = message.data['pedidoId']?.toString() ?? '';

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: payload,
    );
  }

  void _handleMessageNavigation(Map<String, dynamic> data) {
    final pedidoId = data['pedidoId']?.toString();
    if (pedidoId != null && pedidoId.isNotEmpty) {
      _navigateToPedidoId(pedidoId);
    }
  }

  void _navigateToPedidoId(String pedidoId) {
    try {
      final router = createRouter(context.read<AuthNotifier>());
      if (mounted) {
        context.push('/pedido/$pedidoId');
      }
    } catch (e) {
      debugPrint("Erro navegando para pedido $pedidoId: $e");
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
