import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';
import 'package:test/test.dart';

class _FakeDataSource implements DataSource {
  @override
  String get id => 'fake';

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    snapshot.crm['ran'] = true;
  }
}

void main() {
  test('DataSource exposes id and refresh(DataSnapshot)', () async {
    final source = _FakeDataSource();
    final snapshot = DataSnapshot();

    expect(source.id, 'fake');

    await source.refresh(snapshot);

    expect(snapshot.crm['ran'], isTrue);
  });
}
