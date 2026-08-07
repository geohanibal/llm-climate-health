/// Root application widget: theme and the single home route.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import 'pages/home_page.dart';

class ClimateHealthApp extends StatelessWidget {
  const ClimateHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climate-Health Data Integration Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F6F5C),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
