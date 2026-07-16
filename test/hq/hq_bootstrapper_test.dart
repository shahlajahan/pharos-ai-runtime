import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:test/test.dart';

class _PlaceholderHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/placeholder/hq';
}

class _FakeHQBootstrapper extends HQBootstrapper {
  HQSource? capturedSource;

  @override
  Future<HQBootResult> boot(HQSource source) async {
    capturedSource = source;

    return HQBootResult(result: Result.success('booted'), employees: const []);
  }
}

void main() {
  test(
    'HQBootstrapper exposes boot(source) returning an HQBootResult',
    () async {
      final bootstrapper = _FakeHQBootstrapper();
      final source = _PlaceholderHQSource();

      final result = await bootstrapper.boot(source);

      expect(result, isA<HQBootResult>());
    },
  );

  test('HQBootstrapper passes the HQSource through unchanged', () async {
    final bootstrapper = _FakeHQBootstrapper();
    final source = _PlaceholderHQSource();

    await bootstrapper.boot(source);

    expect(bootstrapper.capturedSource, same(source));
  });
}
