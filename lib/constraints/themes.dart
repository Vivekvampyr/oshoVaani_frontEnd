import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  colorScheme: ThemeData.light().colorScheme.copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.lightGreen,
        onSecondary: Colors.white,
      ),
);

final darkTheme = ThemeData.dark().copyWith(
  colorScheme: ThemeData.dark().colorScheme.copyWith(
        primary: const Color.fromARGB(255, 90, 150, 25),
        onPrimary: Colors.white,
        secondary: const Color.fromARGB(255, 90, 150, 25),
        onSecondary: Colors.white,
      ),
);
