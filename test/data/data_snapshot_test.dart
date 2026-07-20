import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:test/test.dart';

void main() {
  test('every section starts empty', () {
    final snapshot = DataSnapshot();

    expect(snapshot.crm, isEmpty);
    expect(snapshot.social, isEmpty);
    expect(snapshot.trends, isEmpty);
    expect(snapshot.news, isEmpty);
    expect(snapshot.analytics, isEmpty);
    expect(snapshot.competitors, isEmpty);
  });

  test('each section can be populated independently', () {
    final snapshot = DataSnapshot();

    snapshot.crm['leads'] = 42;
    snapshot.social['followers'] = 100;

    expect(snapshot.crm['leads'], 42);
    expect(snapshot.social['followers'], 100);
    expect(snapshot.trends, isEmpty);
    expect(snapshot.news, isEmpty);
    expect(snapshot.analytics, isEmpty);
    expect(snapshot.competitors, isEmpty);
  });
}
