import 'package:pharos_ai_runtime/agents/daily_agent.dart';
import 'package:pharos_ai_runtime/agents/marketing_agent.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:test/test.dart';

void main() {
  test('find("marketing") resolves a MarketingAgent', () {
    final agent = AgentRegistry().find('marketing');

    expect(agent, isA<MarketingAgent>());
  });

  test('find("daily") resolves a DailyAgent', () {
    final agent = AgentRegistry().find('daily');

    expect(agent, isA<DailyAgent>());
  });

  test('find() returns null for an unknown id', () {
    final agent = AgentRegistry().find('unknown');

    expect(agent, isNull);
  });
}
