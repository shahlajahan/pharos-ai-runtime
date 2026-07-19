import 'package:pharos_ai_runtime/company/work/work.dart';
import 'package:test/test.dart';

class _FakeWork implements Work {
  @override
  String get id => 'w1';

  @override
  String get title => 'Design the API';
}

void main() {
  test('Work exposes id and title', () {
    final work = _FakeWork();

    expect(work.id, 'w1');
    expect(work.title, 'Design the API');
  });
}
