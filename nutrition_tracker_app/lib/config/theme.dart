import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primarySwatch: MaterialColor(0xFFBC0808, {
    50: Color.fromRGBO(188, 8, 8, .1),
    100: Color.fromRGBO(188, 8, 8, .2),
    200: Color.fromRGBO(188, 8, 8, .3),
    300: Color.fromRGBO(188, 8, 8, .4),
    400: Color.fromRGBO(188, 8, 8, .5),
    500: Color.fromRGBO(188, 8, 8, .6),
    600: Color.fromRGBO(188, 8, 8, .7),
    700: Color.fromRGBO(188, 8, 8, .8),
    800: Color.fromRGBO(188, 8, 8, .9),
    900: Color.fromRGBO(188, 8, 8, 1),
  }),
  scaffoldBackgroundColor: Colors.black,
  useMaterial3: true,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: MaterialColor(0xFFBC0808, {
      50: Color.fromRGBO(188, 8, 8, .1),
      100: Color.fromRGBO(188, 8, 8, .2),
      200: Color.fromRGBO(188, 8, 8, .3),
      300: Color.fromRGBO(188, 8, 8, .4),
      400: Color.fromRGBO(188, 8, 8, .5),
      500: Color.fromRGBO(188, 8, 8, .6),
      600: Color.fromRGBO(188, 8, 8, .7),
      700: Color.fromRGBO(188, 8, 8, .8),
      800: Color.fromRGBO(188, 8, 8, .9),
      900: Color.fromRGBO(188, 8, 8, 1),
    }),
  ).copyWith(secondary: Color.fromARGB(255, 163, 29, 29)),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 163, 29, 29),
    foregroundColor: Colors.white,
    elevation: 1,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  tabBarTheme: const TabBarTheme(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Colors.white, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 188, 8, 8),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
    bodySmall: TextStyle(fontSize: 14, color: Colors.white60),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
    selectedItemColor: Color.fromARGB(255, 188, 8, 8),
    unselectedItemColor: Colors.grey,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
  ),
);
