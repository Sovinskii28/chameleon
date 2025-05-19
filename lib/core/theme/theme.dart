import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  scaffoldBackgroundColor: const Color.fromARGB(255, 240, 227, 189),
  textTheme: TextTheme(
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.cyan[600], // цвет фона
      foregroundColor: Colors.white, // цвет текста и иконок
      elevation: 4, // тень
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // отступы
      shape: RoundedRectangleBorder(
        // форма кнопки
        borderRadius: BorderRadius.circular(8),
      ),
      overlayColor: Colors.blue.shade700,

      textStyle: const TextStyle(
        // стиль текста
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      
    ),
  ),
);
