import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/execution_pipeline.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';

class Runtime {
  Runtime({
    Config config = const Config(),
    AgentRegistry? registry,
    Logger logger = const Logger(),
    HQBootstrap? bootstrap,
    HQSource? source,
  }) : _registry = registry ?? AgentRegistry(),
       _logger = logger,
       _pipeline = ExecutionPipeline(config: config, logger: logger),
       _bootstrap = bootstrap,
       _source = source;

  final AgentRegistry _registry;
  final Logger _logger;
  final ExecutionPipeline _pipeline;
  final HQBootstrap? _bootstrap;
  final HQSource? _source;

  Future<Result?> run(List<String> args) async {
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

    if (_bootstrap != null && _source != null) {
      final bootResult = await _bootstrap.boot(_source);

      if (!bootResult.success) {
        return bootResult;
      }
    }

    return _pipeline.run(agent);
  }
}
