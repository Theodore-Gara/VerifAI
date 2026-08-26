import 'package:flutter/material.dart';

void main() {
  runApp(const VerifAIApp());
}

class VerifAIApp extends StatelessWidget {
  const VerifAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VerifAI',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF02569B),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('VerifAI')),
      ),
    );
  }
}
