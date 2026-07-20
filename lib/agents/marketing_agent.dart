import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';

class MarketingAgent extends Agent {
  @override
  String get id => 'marketing';

  @override
  Future<Result> run(ExecutionContext context) async {
    print('🚀 Marketing Agent Started');
    print('Session : ${context.sessionId}');
    print('Started : ${context.startedAt}');
    print('Env     : ${context.environment}');

    final response = await context.modelProvider.generate(
      const ModelRequest(
        conversation: Conversation(
          messages: [UserMessage(content: 'Say hello from Pharos AI Runtime.')],
        ),
      ),
    );

    print('Response: ${response.text}');

    return Result.success('Marketing agent executed successfully.');
  }
}
