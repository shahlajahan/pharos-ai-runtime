import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/execution_pipeline.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrapper.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/runtime/employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_request_builder.dart';
import 'package:pharos_ai_runtime/tooling/tool_registry.dart';

class Runtime {
  Runtime({
    required this.modelProvider,
    required RuntimeRequestBuilder requestBuilder,
    required EmployeeResponseHandler responseHandler,
    Config config = const Config(),
    AgentRegistry? registry,
    Logger logger = const Logger(),
    HQBootstrapper? bootstrap,
    ToolRegistry? toolRegistry,
  }) : _requestBuilder = requestBuilder,
       _responseHandler = responseHandler,
       _registry = registry ?? AgentRegistry(),
       _logger = logger,
       _pipeline = ExecutionPipeline(config: config, logger: logger),
       _bootstrap = bootstrap,
       _toolRegistry = toolRegistry ?? const ToolRegistry();

  final ModelProvider modelProvider;
  final RuntimeRequestBuilder _requestBuilder;
  final EmployeeResponseHandler _responseHandler;
  final AgentRegistry _registry;
  final Logger _logger;
  final ExecutionPipeline _pipeline;
  final HQBootstrapper? _bootstrap;
  // ignore: unused_field
  final ToolRegistry _toolRegistry;

  Future<Result?> run(List<String> args, {HQSource? source}) async {
    if (args.isEmpty) {
      _logger.info('Usage:');
      _logger.info('pharos marketing');
      return null;
    }

    final agent = _registry.find(args.first);

    if (agent == null) {
      _logger.warning('Unknown agent.');
      return null;
    }

    if (_bootstrap != null && source != null) {
      final bootResult = await _bootstrap.boot(source);

      if (!bootResult.result.success) {
        return bootResult.result;
      }

      EmployeeRuntime? selectedEmployee;

      for (final employee in bootResult.employees) {
        if (employee.definition.id == args.first) {
          selectedEmployee = employee;
          break;
        }
      }

      if (selectedEmployee == null) {
        return Result.failure('Employee "${args.first}" not found.');
      }

      final request = _requestBuilder.build(selectedEmployee);

      try {
        final response = await modelProvider.generate(request);

        return await _responseHandler.handle(selectedEmployee, response);
      } on ModelException catch (e) {
        return Result.failure(e.message);
      }
    }

    final request = _buildModelRequest();
    // ignore: unused_local_variable
    final response = await modelProvider.generate(request);

    return _pipeline.run(agent);
  }

  ModelRequest _buildModelRequest() {
    return const ModelRequest(systemPrompt: '', userPrompt: '');
  }
}
