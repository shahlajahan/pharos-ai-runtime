import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:test/test.dart';

void main() {
  test('LocalHQSource implements HQSource', () {
    final source = LocalHQSource('/some/hq/path');

    expect(source, isA<HQSource>());
  });

  test('LocalHQSource.rootPath() returns the constructor path unchanged', () async {
    final source = LocalHQSource('/some/hq/path');

    final path = await source.rootPath();

    expect(path, '/some/hq/path');
  });

  test('LocalHQSource does not normalize or modify the given path', () async {
    final source = LocalHQSource('relative/../path/');

    final path = await source.rootPath();

    expect(path, 'relative/../path/');
  });
}
