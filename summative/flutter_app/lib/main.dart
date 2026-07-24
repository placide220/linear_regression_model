import 'package:flutter/material.dart';

import 'pages/prediction_page.dart';

void main() => runApp(const CountPredictorApp());

class CountPredictorApp extends StatelessWidget {
  const CountPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connection Count Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2F6FED),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}
