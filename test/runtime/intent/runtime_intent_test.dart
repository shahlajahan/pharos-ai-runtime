import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';
import 'package:test/test.dart';

class _FakeRuntimeIntent implements RuntimeIntent {
  @override
  String get id => 'i1';

  @override
  String get title => 'Release version 2.0';
}

void main() {
  test('RuntimeIntent can be implemented, exposing id and title', () {
    final intent = _FakeRuntimeIntent();

    expect(intent, isA<RuntimeIntent>());
    expect(intent.id, 'i1');
    expect(intent.title, 'Release version 2.0');
  });
}
