import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_context.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/default_employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:pharos_ai_runtime/tooling/tool_invoker.dart';
import 'package:pharos_ai_runtime/tooling/tool_output.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';

/// First public Pharos HQ execution API: executes a single Employee by id
/// with a goal and returns the Runtime's final result.
///
/// HQ owns locating the Employee, creating the initial Conversation (via
/// the goal), and invoking Runtime. It does not add Memory, Planner,
/// Workflow, or Multi-Agent orchestration.
class HQ {
  HQ({
    required ModelProvider modelProvider,
    required HQBootstrapper bootstrap,
    required HQSource source,
    EmployeeResponseHandler? responseHandler,
    ToolRegistry? toolRegistry,
    ToolInvoker? toolInvoker,
  }) : _modelProvider = modelProvider,
       _bootstrap = bootstrap,
       _source = source,
       _responseHandler = responseHandler ?? DefaultEmployeeResponseHandler(),
       _toolRegistry = toolRegistry,
       _toolInvoker = toolInvoker;

  final ModelProvider _modelProvider;
  final HQBootstrapper _bootstrap;
  final HQSource _source;
  final EmployeeResponseHandler _responseHandler;
  final ToolRegistry? _toolRegistry;
  final ToolInvoker? _toolInvoker;

  /// Locates [employee], creates its initial Conversation from [goal], and
  /// invokes Runtime, returning Runtime's result unchanged.
  ///
  /// A ConversationMemory is created automatically for this call (one
  /// Conversation, one Memory). Pass [memory] to supply your own instance
  /// and inspect it afterward; every UserMessage, AssistantMessage, and
  /// ToolMessage produced during execution is recorded into it
  /// automatically — no explicit recording calls are needed.
  Future<Result> execute({
    required String employee,
    required String goal,
    ConversationMemory? memory,
  }) {
    return _run(employee: employee, goal: goal, memory: memory);
  }

  /// Invokes [employee] with [goal] and returns its Result, exactly like
  /// [execute]. This is the entry point one Employee uses to delegate work
  /// to another: only one level of delegation is supported — invoke() does
  /// not recurse and does not chain further invocations itself.
  Future<Result> invoke({
    required String employee,
    required String goal,
    ConversationMemory? memory,
  }) {
    return _run(employee: employee, goal: goal, memory: memory);
  }

  /// Shared execution flow for [execute] and [invoke]: resolves the
  /// Employee, creates one HQContext (and, within it, one
  /// ConversationMemory), executes it through Runtime, and returns the
  /// Result.
  Future<Result> _run({
    required String employee,
    required String goal,
    ConversationMemory? memory,
  }) async {
    final bootResult = await _bootstrap.boot(_source);

    if (!bootResult.result.success) {
      return bootResult.result;
    }

    EmployeeRuntime? selectedEmployee;

    for (final candidate in bootResult.employees) {
      if (candidate.definition.id == employee) {
        selectedEmployee = candidate;
        break;
      }
    }

    if (selectedEmployee == null) {
      return Result.failure('Employee "$employee" not found.');
    }

    final context = HQContext(
      goal: goal,
      employee: selectedEmployee,
      memory: memory,
    );

    final runtime = Runtime(
      modelProvider: _modelProvider,
      requestBuilder: _GoalRequestBuilder(goal: context.goal),
      responseHandler: _responseHandler,
      toolRegistry: _toolRegistry,
      toolInvoker: _toolInvoker,
    );

    return runtime.run(context.employee, memory: context.memory);
  }
}

/// Builds the initial Conversation for an HQ.execute() call: reuses
/// DefaultRuntimeRequestBuilder for the employee-derived SystemMessage,
/// then replaces the empty UserMessage with one containing the goal.
class _GoalRequestBuilder extends RuntimeRequestBuilder {
  _GoalRequestBuilder({required String goal, RuntimeRequestBuilder? base})
    : _goal = goal,
      _base = base ?? DefaultRuntimeRequestBuilder();

  final String _goal;
  final RuntimeRequestBuilder _base;

  @override
  ModelRequest build(
    EmployeeRuntime employee, {
    List<ToolDefinition> tools = const [],
    List<ToolOutput> toolOutputs = const [],
  }) {
    final base = _base.build(employee, tools: tools, toolOutputs: toolOutputs);

    final messages = [
      for (final message in base.conversation.messages)
        if (message is UserMessage) UserMessage(content: _goal) else message,
    ];

    return ModelRequest(
      conversation: Conversation(messages: messages),
      tools: base.tools,
      toolOutputs: base.toolOutputs,
    );
  }
}
