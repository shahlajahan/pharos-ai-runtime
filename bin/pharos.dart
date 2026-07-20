import 'dart:io';

import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/config.dart';
import 'package:pharos_ai_runtime/core/logger.dart';
import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_provider.dart';
import 'package:pharos_ai_runtime/models/model_provider_resolver.dart';
import 'package:pharos_ai_runtime/models/model_registry.dart';
import 'package:pharos_ai_runtime/models/openai_environment.dart';
import 'package:pharos_ai_runtime/models/openai_provider_factory.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/agent_registry.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/runtime/execution_pipeline.dart';

void main(List<String> arguments) async {
  final agentArgs = <String>[];
  HQSource? source;
  HQBootstrap? bootstrap;

  for (var i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--hq' && i + 1 < arguments.length) {
      source = LocalHQSource(arguments[i + 1]);
      bootstrap = HQBootstrap(
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
      );
      i++;
    } else {
      agentArgs.add(arguments[i]);
    }
  }

  final useOpenAI = Platform.environment['OPENAI_ENABLED'] == 'true';

  final providers = <String, ModelProvider>{'mock': MockModelProvider()};

  if (useOpenAI) {
    providers['openai'] = OpenAIProviderFactory().build(
      OpenAIEnvironment.fromMap(Platform.environment),
    );
  }

  final provider = ModelProviderResolver.resolve(
    provider: useOpenAI ? 'openai' : 'mock',
    registry: ModelRegistry(providers: providers),
  );

  if (bootstrap != null && source != null) {
    final hq = HQ(
      modelProvider: provider,
      bootstrap: bootstrap,
      source: source,
    );

    await hq.execute(
      employee: agentArgs.isNotEmpty ? agentArgs.first : '',
      goal: '',
    );

    return;
  }

  const logger = Logger();

  if (agentArgs.isEmpty) {
    logger.info('Usage:');
    logger.info('pharos marketing');
    return;
  }

  final Agent? agent = AgentRegistry().find(agentArgs.first);

  if (agent == null) {
    logger.warning('Unknown agent.');
    return;
  }

  await ExecutionPipeline(
    config: const Config(),
    logger: logger,
    modelProvider: provider,
  ).run(agent);
}
