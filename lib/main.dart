import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/greenhouse_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => GreenhouseProvider())],
      child: MaterialApp(
        title: 'Smart Greenhouse',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        home: const DashboardScreen(),
      ),
    );
  }
}
