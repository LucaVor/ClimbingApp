import 'package:climbingapp/home.dart';
import 'package:flutter/material.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    print(details.exceptionAsString());
    print(details.stack);
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climbing App',
      theme: ThemeData(
        primaryColor: Color(0xFF62BEC1),
        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
        cardColor: Color(0xFF63595C),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFF5AD2F4),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF62BEC1),
        ),
      ),
      home: const HomePage(),
    );
  }
}
