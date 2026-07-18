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
import 'package:pharos_ai_runtime/tooling/delegate_employee_tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';
import 'package:test/test.dart';

/// Returns scripted responses in call order, simulating the model choosing
/// to call delegate_employee on the CEO's first turn, Marketing drafting
/// plain text, and the CEO producing its final answer on the second turn.
/// This is the only fake in this test: everything downstream of a
/// ModelResponse — tool-call detection, ToolInvoker dispatch,
/// DelegateEmployeeTool, HQ.invoke(), the nested Runtime, and the
/// follow-up request — is the real, unmodified pipeline.
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

void _writeEmployee(
  Directory hqDir, {
  required String id,
  required String name,
  required String role,
  required String promptFileName,
  required String promptContent,
}) {
  final employeeDir = Directory('${hqDir.path}/employees/$id');
  employeeDir.createSync(recursive: true);
  File('${employeeDir.path}/employee.md').writeAsStringSync('''
id: $id
name: $name
role: $role
''');
  Directory('${employeeDir.path}/knowledge').createSync();
  Directory('${employeeDir.path}/prompts').createSync();
  File(
    '${employeeDir.path}/prompts/$promptFileName',
  ).writeAsStringSync(promptContent);
}

void main() {
  late Directory hqDir;

  setUp(() {
    hqDir = Directory.systemTemp.createTempSync(
      'employee_delegation_e2e_test_',
    );
    Directory('${hqDir.path}/knowledge').createSync();

    _writeEmployee(
      hqDir,
      id: 'ceo',
      name: 'CEO',
      role: 'Chief Executive Officer',
      promptFileName: 'delegation.md',
      promptContent:
          'When a request requires marketing expertise — writing '
          'announcements, social posts, or campaign copy — delegate it to '
          'the "marketing" Employee using the delegate_employee tool '
          'instead of writing it yourself. Once you receive the delegated '
          'draft, use it to produce your final answer to the user.',
    );

    _writeEmployee(
      hqDir,
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
      promptFileName: 'marketing.md',
      promptContent:
          'You specialize only in marketing tasks: announcements, social '
          'posts, and campaign copy. Do not perform tasks outside of '
          'marketing.',
    );
  });

  tearDown(() {
    if (hqDir.existsSync()) {
      hqDir.deleteSync(recursive: true);
    }
  });

  test('User -> CEO -> ToolCall(delegate_employee) -> Marketing -> ToolOutput '
      '-> CEO -> Final Answer, entirely through the real Runtime + Tool '
      'pipeline', () async {
    const delegateArguments =
        '{"employee":"marketing",'
        '"goal":"Write a LinkedIn announcement for our new Flutter '
        'package."}';

    final modelProvider = _ScriptedModelProvider([
      // 1. CEO's first turn: the model chooses the tool.
      const ModelResponse(
        text: '',
        toolCalls: [
          ToolCall(
            id: 'call_1',
            name: 'delegate_employee',
            arguments: delegateArguments,
          ),
        ],
      ),
      // 2. Marketing's only turn: a plain-text draft, no further tools.
      const ModelResponse(
        text:
            'Draft: Excited to announce our new Flutter package — '
            'available now!',
      ),
      // 3. CEO's second turn, after receiving the ToolOutput.
      const ModelResponse(
        text:
            'Final Answer: Here is your LinkedIn announcement — '
            '"Excited to announce our new Flutter package — available '
            'now!"',
      ),
    ]);

    late final HQ hq;

    final toolRegistry = ToolRegistry(
      tools: {'delegate_employee': DelegateEmployeeTool(hq: () => hq)},
      definitions: const {
        'delegate_employee': ToolDefinition(
          id: 'delegate_employee',
          description: 'Delegate a task to another Employee.',
        ),
      },
    );

    hq = HQ(
      modelProvider: modelProvider,
      bootstrap: HQBootstrap(
        validator: HQValidator(),
        repository: EmployeeRepository(
          discovery: EmployeeDiscovery(),
          loader: EmployeeLoader(),
          parser: MarkdownEmployeeParser(),
        ),
        employeeFactory: EmployeeFactory(
          knowledgeRepository: KnowledgeRepository(
            parser: MarkdownKnowledgeParser(),
          ),
          promptRepository: PromptRepository(parser: MarkdownPromptParser()),
        ),
      ),
      source: LocalHQSource(hqDir.path),
      toolRegistry: toolRegistry,
    );

    final result = await hq.execute(
      employee: 'ceo',
      goal: 'Prepare a LinkedIn announcement for our new Flutter package.',
    );

    // Exactly 3 model turns: CEO -> Marketing -> CEO. No parallel
    // execution, no retries, no further tool calls beyond the one
    // delegation.
    expect(modelProvider.capturedRequests, hasLength(3));

    // Final answer reaches the top-level caller unchanged.
    expect(result.success, isTrue);
    expect(
      result.message,
      contains('Excited to announce our new Flutter package'),
    );

    // Turn 1: the CEO's request carries the user's goal and the
    // delegate_employee tool definition — the model has the tool
    // available and chooses to use it (simulated by the script above).
    final ceoFirstRequest = modelProvider.capturedRequests[0];
    expect(ceoFirstRequest.conversation.messages.last, isA<UserMessage>());
    expect(
      (ceoFirstRequest.conversation.messages.last as UserMessage).content,
      'Prepare a LinkedIn announcement for our new Flutter package.',
    );
    expect(ceoFirstRequest.tools.map((t) => t.id), ['delegate_employee']);

    // Turn 2: Marketing receives the delegated goal as its own goal, via
    // the real HQ.invoke() -> new Runtime.run() path, not the CEO's
    // Conversation.
    final marketingRequest = modelProvider.capturedRequests[1];
    final marketingSystemMessage =
        marketingRequest.conversation.messages.first as SystemMessage;
    final marketingUserMessage =
        marketingRequest.conversation.messages.last as UserMessage;
    expect(marketingSystemMessage.content, contains('Marketing Employee'));
    expect(
      marketingUserMessage.content,
      'Write a LinkedIn announcement for our new Flutter package.',
    );

    // Turn 3: the CEO's second request contains the ToolOutput recorded
    // as a ToolMessage, produced entirely by Runtime's existing tool
    // loop.
    final ceoSecondRequest = modelProvider.capturedRequests[2];
    final ceoToolMessages = ceoSecondRequest.conversation.messages
        .whereType<ToolMessage>();
    expect(ceoToolMessages, hasLength(1));
    expect(
      ceoToolMessages.single.content,
      contains('Excited to announce our new Flutter package'),
    );
  });
}
