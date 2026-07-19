import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/tooling/memory_search_tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';
import 'package:test/test.dart';

/// Returns scripted responses in call order, simulating: turn 1 the CEO
/// simply acknowledging a fact with plain text (no tool call), and turn 2
/// (a separate hq.execute() call sharing the same ConversationMemory) the
/// CEO calling memory_search to recall it before answering. This is the
/// only fake in this test: everything downstream of a ModelResponse — tool
/// -call detection, ToolInvoker dispatch, MemorySearchTool, Runtime's
/// automatic memory recording, and the follow-up request — is the real,
/// unmodified pipeline.
class _ScriptedModelProvider extends ModelProvider {
  _ScriptedModelProvider(this._responses);

  final List<ModelResponse> _responses;
  final List<ModelRequest> capturedRequests = [];

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    capturedRequests.add(request);

    return _responses[capturedRequests.length - 1];
  }
}

HQBootstrap _realBootstrap() => HQBootstrap(
  validator: HQValidator(),
  repository: EmployeeRepository(
    discovery: EmployeeDiscovery(),
    loader: EmployeeLoader(),
    parser: MarkdownEmployeeParser(),
  ),
  employeeFactory: EmployeeFactory(
    knowledgeRepository: KnowledgeRepository(parser: MarkdownKnowledgeParser()),
    promptRepository: PromptRepository(parser: MarkdownPromptParser()),
  ),
);

void main() {
  late Directory hqDir;

  setUp(() {
    hqDir = Directory.systemTemp.createTempSync(
      'employee_conversation_memory_search_e2e_test_',
    );
    Directory('${hqDir.path}/knowledge').createSync();

    final ceoDir = Directory('${hqDir.path}/employees/ceo');
    ceoDir.createSync(recursive: true);
    File('${ceoDir.path}/employee.md').writeAsStringSync('''
id: ceo
name: CEO
role: Chief Executive Officer
''');
    Directory('${ceoDir.path}/knowledge').createSync();
    Directory('${ceoDir.path}/prompts').createSync();
    File('${ceoDir.path}/prompts/memory.md').writeAsStringSync(
      "Before answering a question about something the user told you "
      "earlier in this conversation, consult this conversation's memory "
      'with the memory_search tool.',
    );
  });

  tearDown(() {
    if (hqDir.existsSync()) {
      hqDir.deleteSync(recursive: true);
    }
  });

  test(
    'User -> CEO (turn 1, states a fact) -> [later] User -> CEO (turn 2) -> '
    'ToolCall(memory_search) -> matching earlier entry -> ToolOutput -> CEO '
    '-> Final Answer, entirely through the real Runtime + Tool pipeline',
    () async {
      const memorySearchArguments = '{"query":"PostgreSQL"}';

      final modelProvider = _ScriptedModelProvider([
        // 1. CEO's only turn in the first hq.execute() call: plain text,
        // no tool call.
        const ModelResponse(text: "Got it, I'll remember that preference."),
        // 2. CEO's first turn in the second hq.execute() call: the model
        // chooses memory_search.
        const ModelResponse(
          text: '',
          toolCalls: [
            ToolCall(
              id: 'call_1',
              name: 'memory_search',
              arguments: memorySearchArguments,
            ),
          ],
        ),
        // 3. CEO's second turn in the second call, after receiving the
        // ToolOutput.
        const ModelResponse(
          text: 'Final Answer: Your preferred database is PostgreSQL.',
        ),
      ]);

      final memory = ConversationMemory();

      final toolRegistry = ToolRegistry(
        tools: {'memory_search': MemorySearchTool(store: memory.store)},
        definitions: const {
          'memory_search': ToolDefinition(
            id: 'memory_search',
            description: "Search this conversation's own memory.",
          ),
        },
      );

      final hq = HQ(
        modelProvider: modelProvider,
        bootstrap: _realBootstrap(),
        source: LocalHQSource(hqDir.path),
        toolRegistry: toolRegistry,
      );

      // Turn 1: the user states a fact; the CEO just acknowledges it.
      final firstResult = await hq.execute(
        employee: 'ceo',
        goal: 'My preferred database is PostgreSQL. Remember that.',
        memory: memory,
      );
      expect(firstResult.success, isTrue);

      // Turn 2: a later, separate hq.execute() call, sharing the same
      // ConversationMemory, asks a question that requires recalling turn
      // 1's fact.
      final secondResult = await hq.execute(
        employee: 'ceo',
        goal: 'What is my preferred database?',
        memory: memory,
      );

      // Exactly 3 model turns total: 1 (first call) + 2 (second call). No
      // recursion, no retries.
      expect(modelProvider.capturedRequests, hasLength(3));

      // Final answer reaches the top-level caller unchanged.
      expect(secondResult.success, isTrue);
      expect(secondResult.message, contains('PostgreSQL'));

      // Turn 2's first request offers the memory_search tool.
      final secondCallFirstRequest = modelProvider.capturedRequests[1];
      expect(secondCallFirstRequest.tools.map((t) => t.id), ['memory_search']);

      // Turn 2's second request contains the ToolOutput, recorded as a
      // ToolMessage by Runtime's existing (unmodified) tool loop, and it
      // contains the matching entry recorded automatically during turn 1
      // — never any explicit .record() call from this test.
      final secondCallSecondRequest = modelProvider.capturedRequests[2];
      final toolMessages = secondCallSecondRequest.conversation.messages
          .whereType<ToolMessage>();
      expect(toolMessages, hasLength(1));
      expect(
        toolMessages.single.content,
        contains('My preferred database is PostgreSQL'),
      );

      // The ConversationMemory itself was populated automatically across
      // both calls: turn 1's UserMessage/AssistantMessage, then turn 2's
      // UserMessage/AssistantMessage(tool call)/ToolMessage/
      // AssistantMessage(final answer). SystemMessage is never recorded.
      final entries = await memory.readAll();
      expect(entries, hasLength(6));
    },
  );
}
