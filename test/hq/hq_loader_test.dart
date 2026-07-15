import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_loader.dart';
import 'package:test/test.dart';

class _FakeHQLoader extends HQLoader {
  @override
  Future<Result> load(String path) async => Result.success('loaded: $path');
}

void main() {
  test('HQLoader exposes load(path) returning a Result', () async {
    final loader = _FakeHQLoader();

    final result = await loader.load('/some/hq/path');

    expect(result.success, isTrue);
    expect(result.message, 'loaded: /some/hq/path');
  });
}
