import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const LocalSaleApp());
}

class LocalSaleApp extends StatelessWidget {
  const LocalSaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Sale',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
