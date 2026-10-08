import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'data/sample_medications.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'data/dose_tracking.dart';

import 'services/notification_service.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  startMedicationSync();
  startDoseSync();
  startConnectivityWatch();
  await initNotifications(); // ADDED

  // Wait for Firebase to restore the saved login (if there is one).
  final user = await FirebaseAuth.instance.authStateChanges().first;

  runApp(MediTrackApp(isLoggedIn: user != null));
}

class MediTrackApp extends StatelessWidget {
  final bool isLoggedIn;

  const MediTrackApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediTrack',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF6F9FC),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF172B4D),
          elevation: 0,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
        ),
      ),

      // Signed-in users skip login; everyone else starts at the login screen.
      home: isLoggedIn ? const SplashScreen() : const LoginScreen(),
    );
  }
}
