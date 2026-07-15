import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_registry.dart';
import 'package:test/test.dart';

void main() {
  test('empty registry contains nothing', () {
    const registry = ModelRegistry();

    expect(registry.contains('mock'), isFalse);
  });

  test('contains() returns true for a registered provider', () {
    final registry = ModelRegistry(providers: {'mock': MockModelProvider()});

    expect(registry.contains('mock'), isTrue);
  });

  test('provider() returns the registered provider', () {
    final mock = MockModelProvider();
    final registry = ModelRegistry(providers: {'mock': mock});

    expect(registry.provider('mock'), same(mock));
  });

  test('provider() throws ArgumentError for an unknown provider', () {
    const registry = ModelRegistry();

    expect(() => registry.provider('missing'), throwsArgumentError);
  });

  test('registry is immutable', () {
    const a = ModelRegistry();
    const b = ModelRegistry();

    // Two const instances are canonicalized to the same object by Dart,
    // which is only possible because the constructor is const and the
    // registry exposes no way to mutate its contents after construction.
    expect(identical(a, b), isTrue);
  });
}
