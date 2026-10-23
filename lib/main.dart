import 'package:flutter/material.dart';

import 'src/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TallyBowlApp());
}

class TallyBowlApp extends StatelessWidget {
  const TallyBowlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TallyBowl!',
      debugShowCheckedModeBanner: false,
      theme: tallyBowlTheme,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_baseball_rounded, size: 64),
              SizedBox(height: 24),
              Text(
                'TallyBowl!',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
              ),
              Text('How you bowled, tonight.'),
            ],
          ),
        ),
      ),
    );
  }
}
