import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/agents/marketing_agent.dart';

class AgentRegistry {
  final Map<String, Agent> _agents = {
    'marketing': MarketingAgent(),
  };

  Agent? find(String id) => _agents[id];
}