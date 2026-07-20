import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';
import 'package:pharos_ai_runtime/data/data_source_registry.dart';
import 'package:test/test.dart';

/// A fake DataSource that records when it ran and writes a marker into
/// its own section only, so tests can verify ordering, sharing, and
/// independence without any HTTP, OAuth, browser automation, or file
/// I/O.
class _FakeDataSource implements DataSource {
  _FakeDataSource(this.id, this._callOrder);

  @override
  final String id;

  final List<String> _callOrder;
  DataSnapshot? capturedSnapshot;

  @override
  Future<void> refresh(DataSnapshot snapshot) async {
    _callOrder.add(id);
    capturedSnapshot = snapshot;
    snapshot.crm[id] = true;
  }
}

void main() {
  test('refreshAll() refreshes every connector', () async {
    final callOrder = <String>[];
    final sourceA = _FakeDataSource('a', callOrder);
    final sourceB = _FakeDataSource('b', callOrder);
    final sourceC = _FakeDataSource('c', callOrder);
    final registry = DataSourceRegistry(sources: [sourceA, sourceB, sourceC]);
    final snapshot = DataSnapshot();

    await registry.refreshAll(snapshot);

    expect(callOrder, hasLength(3));
    expect(sourceA.capturedSnapshot, isNotNull);
    expect(sourceB.capturedSnapshot, isNotNull);
    expect(sourceC.capturedSnapshot, isNotNull);
  });

  test(
    'refresh order is preserved, matching the given sources order',
    () async {
      final callOrder = <String>[];
      final registry = DataSourceRegistry(
        sources: [
          _FakeDataSource('first', callOrder),
          _FakeDataSource('second', callOrder),
          _FakeDataSource('third', callOrder),
        ],
      );
      final snapshot = DataSnapshot();

      await registry.refreshAll(snapshot);

      expect(callOrder, ['first', 'second', 'third']);
    },
  );

  test(
    'the same DataSnapshot instance is shared between every connector',
    () async {
      final callOrder = <String>[];
      final sourceA = _FakeDataSource('a', callOrder);
      final sourceB = _FakeDataSource('b', callOrder);
      final registry = DataSourceRegistry(sources: [sourceA, sourceB]);
      final snapshot = DataSnapshot();

      await registry.refreshAll(snapshot);

      expect(sourceA.capturedSnapshot, same(snapshot));
      expect(sourceB.capturedSnapshot, same(snapshot));
      // Both connectors' writes are visible on the one shared snapshot.
      expect(snapshot.crm['a'], isTrue);
      expect(snapshot.crm['b'], isTrue);
    },
  );

  test(
    'connectors remain independent: each only ever touches its own '
    'section, and refreshing one never requires another to have run',
    () async {
      final callOrder = <String>[];
      // Only one connector this time — proves no connector depends on
      // any other connector existing or having run.
      final registry = DataSourceRegistry(
        sources: [_FakeDataSource('solo', callOrder)],
      );
      final snapshot = DataSnapshot();

      await registry.refreshAll(snapshot);

      expect(callOrder, ['solo']);
      expect(snapshot.crm['solo'], isTrue);
      expect(snapshot.social, isEmpty);
      expect(snapshot.trends, isEmpty);
      expect(snapshot.news, isEmpty);
      expect(snapshot.analytics, isEmpty);
      expect(snapshot.competitors, isEmpty);
    },
  );

  test('refreshAll() does nothing for an empty registry', () async {
    const registry = DataSourceRegistry(sources: []);
    final snapshot = DataSnapshot();

    await registry.refreshAll(snapshot);

    expect(snapshot.crm, isEmpty);
  });
}
