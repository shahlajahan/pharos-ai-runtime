import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('`dart run bin/pharos.dart daily` works end-to-end, printing PHAROS '
      'DAILY REPORT and every enabled product name', () async {
    final result = await Process.run('dart', [
      'run',
      'bin/pharos.dart',
      'daily',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());

    final output = result.stdout as String;

    // The report header and every enabled product's name appear. The
    // generated LLM content itself is never asserted exactly, since it
    // is real, non-deterministic model output.
    expect(output, contains('PHAROS DAILY REPORT'));
    expect(output, contains('Petsupo'));
    expect(output, contains('DevAudit'));
    expect(output, contains('HubMonix'));
    expect(output, contains('devclean'));
    expect(output, contains('leadforge'));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
