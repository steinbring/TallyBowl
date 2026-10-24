import 'dart:async';

import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TallyBowlApp());
  // Metadata improves service identification; it must never delay first paint.
  // Requests can use AppConfig's versionless identity until the reply arrives.
  unawaited(AppConfig.initialize());
}
