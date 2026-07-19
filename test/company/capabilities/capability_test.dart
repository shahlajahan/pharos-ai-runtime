import 'package:pharos_ai_runtime/company/capabilities/capability.dart';
import 'package:test/test.dart';

class _FakeCapability implements Capability {
  @override
  String get id => 'fake';

  @override
  String get name => 'Fake Capability';
}

void main() {
  test('Capability can be implemented, exposing id and name', () {
    final capability = _FakeCapability();

    expect(capability, isA<Capability>());
    expect(capability.id, 'fake');
    expect(capability.name, 'Fake Capability');
  });
}
