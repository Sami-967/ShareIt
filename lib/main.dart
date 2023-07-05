import 'package:flutter/material.dart';
import 'package:shareit/home_screen.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        color: Colors.lightBlue,
        debugShowCheckedModeBanner: false,
        home: HomeScreen());
  }
}
