import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final baseScheme = ColorScheme.fromSeed(
       //colores base para generar la paleta de colores
      seedColor: Color.fromARGB(255, 25, 118, 210),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        //color de la superficie
        //surface: Colors.white,
         //color principal de los componentes que utilizan el color primerio
        primary: Color.fromARGB(255, 25, 118, 210),
        //color que apaerece sobre el color primario
        onPrimary: Colors.white,
        //color de mensaje con aviso
        secondary: Color.fromARGB(71, 78, 83, 100),
        //color del ocntenido sobre el fondo secundario
        onSecondary: Colors.white,
        //color de los botones, cuadrados de las opciones de ajustes y ayuda
        surface: Colors.white,
        //color de texto e iconos sobre superficies negras
        onSurface: Colors.black,
        //color destinado a a representar errores o estado problematicos
        error: Colors.red,
        //color de contenido sobre el color de error rojo
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      //fondo general de las pantallas
      scaffoldBackgroundColor: Color.fromARGB(255, 243, 247, 250),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 16),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        //fondo para la barra superior
        backgroundColor: Color.fromARGB(255, 243, 247, 250),
        //color del titulo y de los iconos de la barra superior
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
          horizontal: 24, 
          vertical: 12
          ),
          textStyle: const TextStyle(fontSize: 20),
        minimumSize: const Size(200, 48),
        backgroundColor: Color.fromARGB(255, 25, 118, 210),
        foregroundColor: Colors.white,
       
        ),
      ),
    );
  }
//////alto contraste///////////////////
  static ThemeData highContrastTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        //color principal de los componentes que utilizan el color primerio
        primary: Colors.red,
        //color que apaerece sobre el color primario
        onPrimary: Colors.green,
        //color de mensaje con aviso
        secondary: Colors.blue,
        //color del ocntenido sobre el fondo secundario
        onSecondary: Colors.purple,
        //color de los botones, cuadrados de las opciones de ajustes y ayuda
        surface: Colors.yellow,
        //color de texto e iconos sobre superficies negras
        onSurface: Colors.deepOrange,
        //color destinado a a representar errores o estado problematicos
        error: Colors.pink,
        //color de contenido sobre el color de error rojo
        onError: Colors.teal,
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 18, color: Colors.white),
        bodySmall: TextStyle(fontSize: 18, color: Colors.white),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          
        ),
        titleSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          
        ),
      ),
      ///////Barra colores///////////////
      appBarTheme: const AppBarTheme( 
        centerTitle: true,
        elevation: 0,
        //backgroundColor: Colors.black,
        //foregroundColor: Colors.white,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      ///////Barra colores///////////////
     
      scaffoldBackgroundColor: Colors.black,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          minimumSize: const Size(200, 52),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
         
         
        ),
      ),
    );
  
  }
}

