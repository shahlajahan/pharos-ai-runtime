import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/memory/memory_author.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/planner/plan_step.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/workflow/workflow_context.dart';
import 'package:pharos_ai_runtime/workflow/workflow_step_result.dart';
import 'package:test/test.dart';

class _FakeHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/fake/hq';
}

class _FakeHQBootstrapper extends HQBootstrapper {
  _FakeHQBootstrapper(this._employees);

  final List<EmployeeRuntime> _employees;

  @override
  Future<HQBootResult> boot(HQSource source) async =>
      HQBootResult(result: Result.success('booted'), employees: _employees);
}

class _FailingHQBootstrapper extends HQBootstrapper {
  @override
  Future<HQBootResult> boot(HQSource source) async =>
      HQBootResult(result: Result.failure('boot failed'), employees: const []);
}

class _SpyModelProvider extends ModelProvider {
  ModelRequest? capturedRequest;
  ModelResponse response = const ModelResponse(text: 'ok');

  @override
  Future<ModelResponse> generate(ModelRequest request) async {
    capturedRequest = request;

    return response;
  }
}

void main() {
  const employee = EmployeeRuntime(
    definition: EmployeeDefinition(
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    ),
    knowledge: [],
    prompts: [],
  );

  test('execute() returns the underlying Runtime Result unchanged', () async {
    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(text: 'Done!');
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );

    final result = await hq.execute(
      employee: 'marketing',
      goal: 'Write a LinkedIn post',
    );

    expect(result.success, isTrue);
    expect(result.message, 'Done!');
  });

  test(
    'execute() sends a Conversation whose UserMessage contains the goal',
    () async {
      final modelProvider = _SpyModelProvider();
      final hq = HQ(
        modelProvider: modelProvider,
        bootstrap: _FakeHQBootstrapper([employee]),
        source: _FakeHQSource(),
      );

      await hq.execute(employee: 'marketing', goal: 'Write a LinkedIn post');

      final messages = modelProvider.capturedRequest!.conversation.messages;
      final userMessage = messages.whereType<UserMessage>().single;

      expect(userMessage.content, 'Write a LinkedIn post');
    },
  );

  test('execute() preserves the employee-derived SystemMessage', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );

    await hq.execute(employee: 'marketing', goal: 'Write a LinkedIn post');

    final messages = modelProvider.capturedRequest!.conversation.messages;
    final systemMessage = messages.whereType<SystemMessage>().single;

    expect(systemMessage.content, contains('Marketing Employee'));
    expect(systemMessage.content, contains('Marketing'));
  });

  test('execute() sends exactly a SystemMessage and a UserMessage', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );

    await hq.execute(employee: 'marketing', goal: 'Write a LinkedIn post');

    final messages = modelProvider.capturedRequest!.conversation.messages;

    expect(messages, hasLength(2));
    expect(messages[0], isA<SystemMessage>());
    expect(messages[1], isA<UserMessage>());
  });

  test('execute() returns a failure Result when the employee is not found in '
      'the booted HQ', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper(const []),
      source: _FakeHQSource(),
    );

    final result = await hq.execute(
      employee: 'marketing',
      goal: 'Write a post',
    );

    expect(result.success, isFalse);
  });

  test('execute() returns a failure Result when HQ boot fails', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FailingHQBootstrapper(),
      source: _FakeHQSource(),
    );

    final result = await hq.execute(
      employee: 'marketing',
      goal: 'Write a post',
    );

    expect(result.success, isFalse);
  });

  test(
    'execute() does not leak the goal from one call into the next',
    () async {
      final modelProvider = _SpyModelProvider();
      final hq = HQ(
        modelProvider: modelProvider,
        bootstrap: _FakeHQBootstrapper([employee]),
        source: _FakeHQSource(),
      );

      await hq.execute(employee: 'marketing', goal: 'First goal');
      final firstUserMessage = modelProvider
          .capturedRequest!
          .conversation
          .messages
          .whereType<UserMessage>()
          .single;

      await hq.execute(employee: 'marketing', goal: 'Second goal');
      final secondUserMessage = modelProvider
          .capturedRequest!
          .conversation
          .messages
          .whereType<UserMessage>()
          .single;

      expect(firstUserMessage.content, 'First goal');
      expect(secondUserMessage.content, 'Second goal');
    },
  );

  test('invoke() returns the underlying Runtime Result unchanged', () async {
    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(text: 'Done!');
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );

    final result = await hq.invoke(
      employee: 'marketing',
      goal: 'Write a LinkedIn launch post',
    );

    expect(result.success, isTrue);
    expect(result.message, 'Done!');
  });

  test(
    'invoke() sends a Conversation whose UserMessage contains the goal',
    () async {
      final modelProvider = _SpyModelProvider();
      final hq = HQ(
        modelProvider: modelProvider,
        bootstrap: _FakeHQBootstrapper([employee]),
        source: _FakeHQSource(),
      );

      await hq.invoke(
        employee: 'marketing',
        goal: 'Write a LinkedIn launch post',
      );

      final messages = modelProvider.capturedRequest!.conversation.messages;
      final userMessage = messages.whereType<UserMessage>().single;

      expect(userMessage.content, 'Write a LinkedIn launch post');
    },
  );

  test('invoke() returns a failure Result when the employee is not found in '
      'the booted HQ', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper(const []),
      source: _FakeHQSource(),
    );

    final result = await hq.invoke(employee: 'marketing', goal: 'Write a post');

    expect(result.success, isFalse);
  });

  test('invoke() returns a failure Result when HQ boot fails', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FailingHQBootstrapper(),
      source: _FakeHQSource(),
    );

    final result = await hq.invoke(employee: 'marketing', goal: 'Write a post');

    expect(result.success, isFalse);
  });

  test('execute() produces a populated ConversationMemory without any '
      'explicit calls from user code', () async {
    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(text: 'Done!');
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );
    final memory = ConversationMemory();

    await hq.execute(
      employee: 'marketing',
      goal: 'Write a LinkedIn post',
      memory: memory,
    );

    final entries = await memory.readAll();

    expect(entries, hasLength(2));
    expect(entries[0].author, MemoryAuthor.user);
    expect(entries[0].content, 'Write a LinkedIn post');
    expect(entries[1].author, MemoryAuthor.employee);
    expect(entries[1].content, 'Done!');
  });

  test('invoke() produces a populated ConversationMemory without any '
      'explicit calls from user code', () async {
    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(text: 'Done!');
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );
    final memory = ConversationMemory();

    await hq.invoke(
      employee: 'marketing',
      goal: 'Write a LinkedIn launch post',
      memory: memory,
    );

    final entries = await memory.readAll();

    expect(entries, hasLength(2));
    expect(entries[0].author, MemoryAuthor.user);
    expect(entries[1].author, MemoryAuthor.employee);
    expect(entries[1].content, 'Done!');
  });

  test('execute() still creates its own ConversationMemory automatically when '
      'none is given (no crash, no explicit memory required)', () async {
    final modelProvider = _SpyModelProvider()
      ..response = const ModelResponse(text: 'Done!');
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );

    final result = await hq.execute(
      employee: 'marketing',
      goal: 'Write a LinkedIn post',
    );

    expect(result.success, isTrue);
  });

  test(
    'execute() and invoke() produce identical observable behavior for the '
    'same inputs, confirming they share the same internal execution flow',
    () async {
      final executeProvider = _SpyModelProvider()
        ..response = const ModelResponse(text: 'Same result');
      final executeHq = HQ(
        modelProvider: executeProvider,
        bootstrap: _FakeHQBootstrapper([employee]),
        source: _FakeHQSource(),
      );

      final invokeProvider = _SpyModelProvider()
        ..response = const ModelResponse(text: 'Same result');
      final invokeHq = HQ(
        modelProvider: invokeProvider,
        bootstrap: _FakeHQBootstrapper([employee]),
        source: _FakeHQSource(),
      );

      final executeResult = await executeHq.execute(
        employee: 'marketing',
        goal: 'Write a post',
      );
      final invokeResult = await invokeHq.invoke(
        employee: 'marketing',
        goal: 'Write a post',
      );

      expect(invokeResult.success, executeResult.success);
      expect(invokeResult.message, executeResult.message);
      expect(
        invokeProvider.capturedRequest!.conversation.messages.length,
        executeProvider.capturedRequest!.conversation.messages.length,
      );
      expect(
        (invokeProvider.capturedRequest!.conversation.messages
                .whereType<UserMessage>()
                .single)
            .content,
        (executeProvider.capturedRequest!.conversation.messages
                .whereType<UserMessage>()
                .single)
            .content,
      );
    },
  );

  test('invoke() without a context sends the bare goal, exactly as before '
      'WorkflowContext existed', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );

    await hq.invoke(employee: 'marketing', goal: 'Review architecture');

    final userMessage = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single;
    expect(userMessage.content, 'Review architecture');
  });

  test('invoke() with a context that has no previousSteps sends the bare '
      'goal, unchanged', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );

    await hq.invoke(
      employee: 'marketing',
      goal: 'Review architecture',
      context: const WorkflowContext(previousSteps: []),
    );

    final userMessage = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single;
    expect(userMessage.content, 'Review architecture');
  });

  test('invoke() with a context carrying previousSteps prepends a '
      'deterministic "Previous Workflow Results" summary before "Current '
      'Goal" and the goal itself', () async {
    final modelProvider = _SpyModelProvider();
    final hq = HQ(
      modelProvider: modelProvider,
      bootstrap: _FakeHQBootstrapper([employee]),
      source: _FakeHQSource(),
    );
    final context = WorkflowContext(
      previousSteps: [
        WorkflowStepResult(
          step: const PlanStep(
            description: 'Research competitors',
            assignedEmployee: 'research',
          ),
          result: Result.success('Competitor research complete.'),
        ),
      ],
    );

    await hq.invoke(
      employee: 'marketing',
      goal: 'Review architecture',
      context: context,
    );

    final userMessage = modelProvider.capturedRequest!.conversation.messages
        .whereType<UserMessage>()
        .single;
    expect(userMessage.content, contains('Previous Workflow Results'));
    expect(userMessage.content, contains('Competitor research complete.'));
    expect(userMessage.content, contains('Current Goal'));
    expect(userMessage.content, endsWith('Review architecture'));
  });
}
