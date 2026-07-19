import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/tooling/delegate_employee_tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';
import 'package:pharos_ai_runtime/workflow/workflow_context.dart';
import 'package:test/test.dart';

class _FakeHQSource extends HQSource {
  @override
  Future<String> rootPath() async => '/fake/hq';
}

class _FakeModelProvider extends ModelProvider {
  @override
  Future<ModelResponse> generate(ModelRequest request) async =>
      const ModelResponse(text: 'unused');
}

class _FakeHQBootstrapper extends HQBootstrapper {
  @override
  Future<HQBootResult> boot(HQSource source) async =>
      HQBootResult(result: Result.success('booted'), employees: const []);
}

class _SpyHQ extends HQ {
  _SpyHQ()
    : super(
        modelProvider: _FakeModelProvider(),
        bootstrap: _FakeHQBootstrapper(),
        source: _FakeHQSource(),
      );

  int callCount = 0;
  String? capturedEmployee;
  String? capturedGoal;
  Result response = Result.success('delegated result');

  @override
  Future<Result> invoke({
    required String employee,
    required String goal,
    ConversationMemory? memory,
    WorkflowContext? context,
  }) async {
    callCount++;
    capturedEmployee = employee;
    capturedGoal = goal;

    return response;
  }
}

class _NestedDelegationHQ extends HQ {
  _NestedDelegationHQ()
    : super(
        modelProvider: _FakeModelProvider(),
        bootstrap: _FakeHQBootstrapper(),
        source: _FakeHQSource(),
      );

  DelegateEmployeeTool? tool;

  @override
  Future<Result> invoke({
    required String employee,
    required String goal,
    ConversationMemory? memory,
    WorkflowContext? context,
  }) {
    // Simulates the delegated Employee's own tool-calling loop invoking
    // delegate_employee again before this outer call has returned.
    return tool!.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"sales","goal":"nested goal"}',
      ),
    );
  }
}

void main() {
  test('id is "delegate_employee"', () {
    final tool = DelegateEmployeeTool(hq: () => _SpyHQ());

    expect(tool.id, 'delegate_employee');
  });

  test('execute() calls HQ.invoke() with the employee and goal from arguments, '
      'returning its Result unchanged', () async {
    final hq = _SpyHQ()..response = Result.success('Post written!');
    final tool = DelegateEmployeeTool(hq: () => hq);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"marketing","goal":"Write a post"}',
      ),
    );

    expect(hq.callCount, 1);
    expect(hq.capturedEmployee, 'marketing');
    expect(hq.capturedGoal, 'Write a post');
    expect(result.success, isTrue);
    expect(result.message, 'Post written!');
  });

  test('execute() propagates a failing delegated Result unchanged', () async {
    final hq = _SpyHQ()..response = Result.failure('Employee "x" not found.');
    final tool = DelegateEmployeeTool(hq: () => hq);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"x","goal":"Do something"}',
      ),
    );

    expect(result.success, isFalse);
    expect(result.message, 'Employee "x" not found.');
  });

  test('execute() returns Result.failure for invalid JSON arguments', () async {
    final hq = _SpyHQ();
    final tool = DelegateEmployeeTool(hq: () => hq);

    final result = await tool.execute(
      const ToolContext(toolId: 'delegate_employee', arguments: 'not json'),
    );

    expect(result.success, isFalse);
    expect(hq.callCount, 0);
  });

  test(
    'execute() returns Result.failure when arguments is not a JSON object',
    () async {
      final hq = _SpyHQ();
      final tool = DelegateEmployeeTool(hq: () => hq);

      final result = await tool.execute(
        const ToolContext(toolId: 'delegate_employee', arguments: '[]'),
      );

      expect(result.success, isFalse);
      expect(hq.callCount, 0);
    },
  );

  test('execute() returns Result.failure when "employee" is missing', () async {
    final hq = _SpyHQ();
    final tool = DelegateEmployeeTool(hq: () => hq);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"goal":"Write a post"}',
      ),
    );

    expect(result.success, isFalse);
    expect(hq.callCount, 0);
  });

  test('execute() returns Result.failure when "goal" is missing', () async {
    final hq = _SpyHQ();
    final tool = DelegateEmployeeTool(hq: () => hq);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"marketing"}',
      ),
    );

    expect(result.success, isFalse);
    expect(hq.callCount, 0);
  });

  test('execute() returns Result.failure when "employee" is empty', () async {
    final hq = _SpyHQ();
    final tool = DelegateEmployeeTool(hq: () => hq);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"","goal":"Write a post"}',
      ),
    );

    expect(result.success, isFalse);
    expect(hq.callCount, 0);
  });

  test('execute() returns Result.failure when "goal" is empty', () async {
    final hq = _SpyHQ();
    final tool = DelegateEmployeeTool(hq: () => hq);

    final result = await tool.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"marketing","goal":""}',
      ),
    );

    expect(result.success, isFalse);
    expect(hq.callCount, 0);
  });

  test('execute() rejects nested delegation with a clear error, without '
      'delegating twice', () async {
    final hq = _NestedDelegationHQ();
    final tool = DelegateEmployeeTool(hq: () => hq);
    hq.tool = tool;

    final result = await tool.execute(
      const ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"marketing","goal":"Write a post"}',
      ),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('Nested delegation'));
  });

  test(
    'execute() allows a fresh delegation after a previous one completed',
    () async {
      final hq = _SpyHQ();
      final tool = DelegateEmployeeTool(hq: () => hq);
      const context = ToolContext(
        toolId: 'delegate_employee',
        arguments: '{"employee":"marketing","goal":"Write a post"}',
      );

      final firstResult = await tool.execute(context);
      final secondResult = await tool.execute(context);

      expect(firstResult.success, isTrue);
      expect(secondResult.success, isTrue);
      expect(hq.callCount, 2);
    },
  );
}
