import 'package:flutter/material.dart';

import 'pages/prediction_page.dart';
import 'theme/app_theme.dart';

void main() => runApp(const CountPredictorApp());

class CountPredictorApp extends StatelessWidget {
  const CountPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connection Count Predictor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const PredictionPage(),
    );
  }
}
