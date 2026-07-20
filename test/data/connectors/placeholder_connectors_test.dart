import 'package:pharos_ai_runtime/data/connectors/analytics/analytics_data_source.dart';
import 'package:pharos_ai_runtime/data/connectors/competitors/competitor_data_source.dart';
import 'package:pharos_ai_runtime/data/connectors/crm/crm_data_source.dart';
import 'package:pharos_ai_runtime/data/connectors/news/news_data_source.dart';
import 'package:pharos_ai_runtime/data/connectors/social/social_data_source.dart';
import 'package:pharos_ai_runtime/data/connectors/trends/trends_data_source.dart';
import 'package:pharos_ai_runtime/data/data_snapshot.dart';
import 'package:pharos_ai_runtime/data/data_source.dart';
import 'package:test/test.dart';

const _workspaceRoot = '/tmp/pharos-hq';

void main() {
  final connectorsById = <String, DataSource>{
    'crm': const CrmDataSource(workspaceRoot: _workspaceRoot),
    'social': const SocialDataSource(workspaceRoot: _workspaceRoot),
    'trends': const TrendsDataSource(workspaceRoot: _workspaceRoot),
    'news': const NewsDataSource(workspaceRoot: _workspaceRoot),
    'analytics': const AnalyticsDataSource(workspaceRoot: _workspaceRoot),
    'competitors': const CompetitorDataSource(workspaceRoot: _workspaceRoot),
  };

  test('every placeholder connector implements DataSource with the '
      'expected id', () {
    for (final entry in connectorsById.entries) {
      expect(entry.value, isA<DataSource>());
      expect(entry.value.id, entry.key);
    }
  });

  test('every placeholder connector\'s refresh() completes without any HTTP, '
      'OAuth, browser automation, or file I/O, and without throwing', () async {
    for (final connector in connectorsById.values) {
      await expectLater(connector.refresh(DataSnapshot()), completes);
    }
  });
}
