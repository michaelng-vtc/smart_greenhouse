import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/greenhouse_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, GreenhouseProvider>(
          create: (_) => GreenhouseProvider(),
          update: (_, settings, greenhouse) {
            greenhouse!.updateSettings(settings);
            return greenhouse;
          },
        ),
        ChangeNotifierProxyProvider<GreenhouseProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, greenhouse, cart) {
            cart!.updateApiUrl(greenhouse.apiUrl);
            return cart;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Smart Greenhouse',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
            locale: settings.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('zh'), // Chinese
            ],
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
