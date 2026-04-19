import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/vehicle_provider.dart';
import 'providers/session_provider.dart';
import 'providers/user_provider.dart';

import 'screens/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'widgets/animated_gradient_background.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: const MotoLapTimerApp(),
    ),
  );
}

class MotoLapTimerApp extends StatelessWidget {
  const MotoLapTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoLapTimer',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('uk'), Locale('en')],
      locale: const Locale('ru'), // Default to Russian
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
          primary: Colors.deepPurple,
          secondary: Colors.lightGreen,
          background: const Color(0xFFF5F5F5),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      home: const MainGate(),
    );
  }
}

class MainGate extends StatelessWidget {
  const MainGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Consumer2<UserProvider, VehicleProvider>(
        builder: (context, userProvider, vehicleProvider, child) {
          if (userProvider.isLoading || vehicleProvider.isLoading) {
            return const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            );
          }

          if (userProvider.needsProfileOnboarding ||
              vehicleProvider.needsOnboarding) {
            return const OnboardingScreen();
          }

          return const RootScreen();
        },
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MotoLapTimer')),
      body: const Center(
        child: Text('App Initialized', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
