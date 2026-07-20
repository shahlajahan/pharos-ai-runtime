import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('`dart run bin/pharos.dart daily` works end-to-end, grounding the '
      'report on a real HQ workspace', () async {
    final workspace = Directory.systemTemp.createTempSync(
      'daily_cli_e2e_test_',
    );

    try {
      final companyDir = Directory('${workspace.path}/company')..createSync();
      File(
        '${companyDir.path}/overview.md',
      ).writeAsStringSync('# Overview\n\nWe build developer tools.');

      final result = await Process.run(
        'dart',
        ['run', 'bin/pharos.dart', 'daily'],
        environment: {'PHAROS_HQ_ROOT': workspace.path},
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final stdout = result.stdout as String;
      expect(stdout, contains('PHAROS TODAY'));
      expect(stdout, contains('Blocked Items'));
      expect(stdout, contains('Missing Operational Data'));
      expect(stdout, contains('Recommended Next Connections'));
    } finally {
      if (workspace.existsSync()) {
        workspace.deleteSync(recursive: true);
      }
    }
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('`dart run bin/pharos.dart daily` still executes successfully when no '
      'HQ workspace is present', () async {
    final result = await Process.run('dart', [
      'run',
      'bin/pharos.dart',
      'daily',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout as String, contains('PHAROS TODAY'));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
