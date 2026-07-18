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
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/tooling/knowledge_search_tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';
import 'package:test/test.dart';

/// Returns scripted responses in call order, simulating the model choosing
/// to call knowledge_search on the CEO's first turn, then producing its
/// final answer once it has the ToolOutput. This is the only fake in this
/// test: everything downstream of a ModelResponse — tool-call detection,
/// ToolInvoker dispatch, KnowledgeSearchTool, and the follow-up request —
/// is the real, unmodified pipeline.
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
      'employee_knowledge_retrieval_e2e_test_',
    );
    Directory('${hqDir.path}/knowledge').createSync();

    final ceoDir = Directory('${hqDir.path}/employees/ceo');
    ceoDir.createSync(recursive: true);
    File('${ceoDir.path}/employee.md').writeAsStringSync('''
id: ceo
name: CEO
role: Chief Executive Officer
''');
    Directory('${ceoDir.path}/prompts').createSync();
    File('${ceoDir.path}/prompts/knowledge.md').writeAsStringSync(
      'Before answering questions about how internal systems work, '
      'consult your knowledge base with the knowledge_search tool.',
    );
    Directory('${ceoDir.path}/knowledge').createSync();
    File('${ceoDir.path}/knowledge/commission-engine.md').writeAsStringSync('''
# Commission Engine

The commission engine calculates payouts based on tiered sales targets:
5% up to \$10k, 8% up to \$50k, and 12% beyond that.
''');
    File('${ceoDir.path}/knowledge/onboarding.md').writeAsStringSync('''
# Onboarding Guide

Welcome to the team.
''');
  });

  tearDown(() {
    if (hqDir.existsSync()) {
      hqDir.deleteSync(recursive: true);
    }
  });

  test('User -> CEO -> ToolCall(knowledge_search) -> matching documents -> '
      'ToolOutput -> CEO -> Final Answer, entirely through the real Runtime '
      '+ Tool pipeline', () async {
    // Resolve the real, HQBootstrap-produced EmployeeRuntime once, so
    // KnowledgeSearchTool is scoped to exactly this Employee's own
    // knowledge — never another Employee's documents, and never loaded
    // through any mechanism other than the existing KnowledgeRepository.
    final bootResult = await _realBootstrap().boot(LocalHQSource(hqDir.path));
    expect(bootResult.result.success, isTrue);
    final ceo = bootResult.employees.single;
    expect(ceo.knowledge, hasLength(2));

    const knowledgeSearchArguments = '{"query":"commission engine"}';

    final modelProvider = _ScriptedModelProvider([
      // 1. CEO's first turn: the model chooses the tool.
      const ModelResponse(
        text: '',
        toolCalls: [
          ToolCall(
            id: 'call_1',
            name: 'knowledge_search',
            arguments: knowledgeSearchArguments,
          ),
        ],
      ),
      // 2. CEO's second turn, after receiving the ToolOutput.
      const ModelResponse(
        text:
            'Final Answer: Our commission engine pays 5% up to \$10k, 8% '
            'up to \$50k, and 12% beyond that.',
      ),
    ]);

    final toolRegistry = ToolRegistry(
      tools: {
        'knowledge_search': KnowledgeSearchTool(knowledge: ceo.knowledge),
      },
      definitions: const {
        'knowledge_search': ToolDefinition(
          id: 'knowledge_search',
          description: "Search this Employee's own knowledge base.",
        ),
      },
    );

    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _realBootstrap(),
      source: LocalHQSource(hqDir.path),
      toolRegistry: toolRegistry,
    );

    final result = await hq.execute(
      employee: 'ceo',
      goal: 'How does our commission engine work?',
    );

    // Exactly 2 model turns: no recursion, no retries, no further tool
    // calls beyond the one knowledge_search lookup.
    expect(modelProvider.capturedRequests, hasLength(2));

    // Final answer reaches the top-level caller unchanged.
    expect(result.success, isTrue);
    expect(result.message, contains('5% up to \$10k'));

    // Turn 1: the CEO's request offers the knowledge_search tool.
    final firstRequest = modelProvider.capturedRequests[0];
    expect(firstRequest.tools.map((t) => t.id), ['knowledge_search']);

    // Turn 2: the CEO's second request contains the ToolOutput, recorded
    // as a ToolMessage by Runtime's existing (unmodified) tool loop, and
    // it contains only the matching document's content — not the
    // unrelated onboarding document.
    final secondRequest = modelProvider.capturedRequests[1];
    final toolMessages = secondRequest.conversation.messages
        .whereType<ToolMessage>();
    expect(toolMessages, hasLength(1));
    expect(toolMessages.single.content, contains('tiered sales targets'));
    expect(toolMessages.single.content, isNot(contains('Welcome to the team')));
  });
}
