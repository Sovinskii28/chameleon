import 'package:chamelion_app/core/theme/theme.dart';
import 'package:chamelion_app/features/home/presentation/screen/home_screen.dart';
import 'package:flutter/material.dart';

class ChamelionApp extends StatelessWidget {
  const ChamelionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: const HomeScreen(),
    );
  }
}