import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:test/test.dart';

class _FakeHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/some/hq/path';
}

void main() {
  test('HQSource exposes rootPath() returning a String', () async {
    final source = _FakeHQSource();

    final path = await source.rootPath();

    expect(path, '/some/hq/path');
  });
}
