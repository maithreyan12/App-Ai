import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AiPhotoEnhancerApp());
}

class AiPhotoEnhancerApp extends StatelessWidget {
  const AiPhotoEnhancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Photo Enhancer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}