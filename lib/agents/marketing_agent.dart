import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';

class MarketingAgent extends Agent {
  @override
  String get id => 'marketing';

  @override
  Future<void> run(ExecutionContext context) async {
    print('🚀 Marketing Agent Started');
    print('Session : ${context.sessionId}');
    print('Started : ${context.startedAt}');
    print('Env     : ${context.environment}');
  }
}