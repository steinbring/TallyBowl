// Development-only evaluator. Run explicitly; never bundled with the app.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallybowl/src/domain/models.dart';
import 'package:tallybowl/src/domain/scoring.dart';
import 'package:tallybowl/src/recognition/photo_service.dart';
import 'package:tallybowl/src/recognition/score_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const manifestPath = String.fromEnvironment('LAB_MANIFEST');
  const outputPath = String.fromEnvironment('LAB_OUTPUT');
  const engine = String.fromEnvironment('LAB_ENGINE');
  const templatesPath = String.fromEnvironment('LAB_TEMPLATES');
  const cachePath = String.fromEnvironment(
    'LAB_CACHE',
    defaultValue: 'build/recognition-lab/native-cache',
  );
  const serial = String.fromEnvironment(
    'LAB_SERIAL',
    defaultValue: 'emulator-5554',
  );
  test('paired original-photo evaluation', () async {
    expect(manifestPath, isNotEmpty);
    expect(outputPath, isNotEmpty);
    expect(engine, isIn(['apple', 'android']));
    final validation = await Process.run('python3', [
      'tool/recognition_lab/lab.py',
      'validate',
      manifestPath,
    ]);
    expect(validation.exitCode, 0, reason: validation.stderr.toString());
    final manifestBytes = File(manifestPath).readAsBytesSync();
    final document = jsonDecode(utf8.decode(manifestBytes)) as Map;
    final cases = document['cases'] as List;
    final output = File(outputPath);
    output.parent.createSync(recursive: true);
    final work = Directory('${output.path}.work')..createSync(recursive: true);
    final nativeArgs = [
      'tool/recognition_lab/native_request.py',
      '--engine',
      engine,
      '--cache',
      cachePath,
      '--serial',
      serial,
    ];
    final version = await Process.run('python3', [
      ...nativeArgs,
      '--fingerprint',
    ]);
    expect(version.exitCode, 0, reason: version.stderr.toString());
    final pipelineFiles = [
      ...Directory('lib/src/recognition').listSync().whereType<File>(),
      File('lib/src/domain/scoring.dart'),
      File('tool/recognition_lab/evaluate_test.dart'),
      File('tool/recognition_lab/native_request.py'),
    ]..sort((a, b) => a.path.compareTo(b.path));
    final pipeline = sha256.convert([
      for (final file in pipelineFiles) ...[
        ...utf8.encode(file.path),
        0,
        ...file.readAsBytesSync(),
        0,
      ],
    ]).toString();
    final asset = File(
      templatesPath.isEmpty ? 'assets/recognition/glyphs.json' : templatesPath,
    ).readAsBytesSync();
    if (templatesPath.isNotEmpty) {
      // Inject only in the test messenger. Production has no override switch.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final key = utf8.decode(
              message!.buffer.asUint8List(
                message.offsetInBytes,
                message.lengthInBytes,
              ),
            );
            final data = key == 'assets/recognition/glyphs.json'
                ? asset
                : File(key).readAsBytesSync();
            return ByteData.sublistView(data);
          });
    }
    final results = <Map<String, Object?>>[];
    for (final raw in cases) {
      final item = raw as Map;
      final id = item['id'] as String;
      final profile = item['profile'] as Map;
      final bowler = BowlerProfile(
        name: profile['name'] as String,
        aliases: (profile['aliases'] as List? ?? []).cast<String>(),
      );
      if (item['status'] == 'complete') {
        final gold = TenPinScorer.score(
          (item['frames'] as List).cast<String>(),
        );
        expect(gold.complete, true, reason: '$id invalid gold');
        expect(
          gold.cumulative,
          item['cumulative'],
          reason: '$id gold conflict',
        );
      }
      var calls = 0;
      final timer = Stopwatch()..start();
      var exact = false, wrong = false;
      String? error;
      var nativeFailed = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PhotoService.channel, (call) async {
            final args = call.arguments as Map;
            final request = File('${work.path}/$id-${calls++}.request.json');
            final response = File('${request.path}.response.json');
            request.writeAsStringSync(
              jsonEncode({
                'path': File(item['path'] as String).absolute.path,
                'sha256': item['sha256'],
                'args': {
                  for (final key in ['aspect', 'regions', 'context'])
                    if (args.containsKey(key)) key: args[key],
                },
              }),
            );
            final process = await Process.run('python3', [
              ...nativeArgs,
              request.path,
              response.path,
            ]);
            if (process.exitCode != 0) {
              nativeFailed = true;
              File('${request.path}.error.txt')
                  .writeAsStringSync(process.stderr.toString());
              throw StateError(
                'Native request failed; inspect private work files',
              );
            }
            return jsonDecode(response.readAsStringSync());
          });
      try {
        final lines = await PhotoService.recognize(
          item['path'] as String,
          profile: bowler,
        );
        final rows = ScoreSheetParser.rows(lines, bowler);
        File('${work.path}/$id.rows.json').writeAsStringSync(
          jsonEncode([
            for (final row in rows)
              {
                'text': row.text,
                'frames': row.frames,
                'total': row.displayedTotal,
                'automatic': row.canAutoSelect,
              },
          ]),
        );
        final automatic = rows.where((r) => r.canAutoSelect).toList();
        bool matches(ScoreRow row) =>
            item['status'] == 'complete' &&
            jsonEncode(row.frames) == jsonEncode(item['frames']) &&
            row.displayedTotal == (item['cumulative'] as List).last;
        final row = ScoreSheetParser.automaticRow(rows);
        exact = row != null && matches(row);
        // Inspect every automatic candidate, including ambiguous multiple rows.
        wrong = automatic.any((r) => !matches(r));
      } catch (_) {
        error = 'evaluation_failed';
      }
      if (nativeFailed) error = 'native_request_failed';
      results.add({
        'id': id,
        'family': item['family'],
        'split': item['split'],
        'status': item['status'],
        'exact': exact,
        'wrongAutomatic': wrong,
        'calls': calls,
        'milliseconds': timer.elapsedMilliseconds,
        'error': ?error,
      });
      // Reports contain opaque IDs and metrics; OCR text/names stay in work/cache.
      output.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'schema': 1,
          'manifestSha256': sha256.convert(manifestBytes).toString(),
          'engine': engine,
          'nativeFingerprint': version.stdout.toString().trim(),
          'pipelineSha256': pipeline,
          'templatesSha256': sha256.convert(asset).toString(),
          'expectedCases': cases.length,
          'complete': results.length == cases.length,
          'cases': results,
        }),
      );
      stdout.writeln(
        '$engine $id: ${exact ? "exact" : "review"}${wrong ? " WRONG" : ""}${error == null ? "" : " ERROR"}',
      );
    }
    expect(results.where((r) => r['error'] != null), isEmpty);
    expect(results.every((r) => (r['calls'] as int) <= 4), true);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
