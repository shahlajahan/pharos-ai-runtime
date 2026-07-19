import 'package:pharos_ai_runtime/company/intent/intent.dart';
import 'package:test/test.dart';

class _FakeIntent implements Intent {
  @override
  String get id => 'i1';

  @override
  String get title => 'Release version 2.0';
}

void main() {
  test('Intent can be implemented, exposing id and title', () {
    final intent = _FakeIntent();

    expect(intent, isA<Intent>());
    expect(intent.id, 'i1');
    expect(intent.title, 'Release version 2.0');
  });
}
