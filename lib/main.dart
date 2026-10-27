import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'src/app.dart';
import 'src/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Roboto score glyph templates',
    ], await rootBundle.loadString('assets/recognition/OFL-Roboto.txt'));
  });
  runApp(const TallyBowlApp());
  // Metadata improves service identification; it must never delay first paint.
  // Requests can use AppConfig's versionless identity until the reply arrives.
  unawaited(AppConfig.initialize());
}
