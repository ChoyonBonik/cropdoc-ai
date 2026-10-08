import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CropDocApp());
}

class CropDocApp extends StatelessWidget {
  const CropDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropDoc AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Emerald Forest Green
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
