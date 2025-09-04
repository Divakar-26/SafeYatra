import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Auth UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
      // Optional: Define routes for better navigation management
      routes: {
        '/auth': (context) => const AuthScreen(),
        // '/home': (context) => HomeScreen(username: ModalRoute.of(context)!.settings.arguments as String),
      },
    );
  }
}