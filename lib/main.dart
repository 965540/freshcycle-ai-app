import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/welcome_screen.dart';
import 'screens/offer_detail_screen.dart';

// ✅ Global keys
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

// 🔔 Background handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(const FreshCycleApp());
}

class FreshCycleApp extends StatefulWidget {
  const FreshCycleApp({super.key});

  @override
  State<FreshCycleApp> createState() => _FreshCycleAppState();
}

class _FreshCycleAppState extends State<FreshCycleApp> {

  @override
  void initState() {
    super.initState();
    setupNotifications();
  }

  Future<void> setupNotifications() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();
    await messaging.subscribeToTopic("offers");

    final token = await messaging.getToken();
    debugPrint("DEVICE TOKEN: $token");

    // 🔔 Foreground notification
    FirebaseMessaging.onMessage.listen((message) {
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? "New Offer"),
        ),
      );
    });

    // 🔔 Notification click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = message.data;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => OfferDetailScreen(offer: data),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey, // ✅ IMPORTANT
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}