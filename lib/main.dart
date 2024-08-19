import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:amc/views/bienvenidaView.dart';
import 'Admin/connection_aware_widget.dart';
import 'api/apifirebase.dart';
import 'firebase_options.dart';
import 'package:amc/helpers/timezone_helper.dart';

// final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  await FirebaseMessaging.instance.subscribeToTopic('all');
  TimeZoneHelper.initializeTimeZones();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  ConnectionAwareWidget(
      inactivitySeconds: 2,
      child:  MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0XFF001220),
            ),
            home: const Bienvenidaview(),
            // navigatorKey: navigatorKey,
            
          ),
    ); 
  }
}
