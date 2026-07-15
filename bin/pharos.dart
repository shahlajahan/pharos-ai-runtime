import 'package:pharos_ai_runtime/employees/employee_repository.dart';
import 'package:pharos_ai_runtime/employees/markdown_employee_parser.dart';
import 'package:pharos_ai_runtime/hq/employee_discovery.dart';
import 'package:pharos_ai_runtime/hq/employee_loader.dart';
import 'package:pharos_ai_runtime/hq/hq_bootstrap.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/hq/hq_validator.dart';
import 'package:pharos_ai_runtime/hq/local_hq_source.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_repository.dart';
import 'package:pharos_ai_runtime/knowledge/markdown_knowledge_parser.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';

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
        loader: EmployeeLoader(),
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

  final runtime = Runtime(bootstrap: bootstrap);

  await runtime.run(agentArgs, source: source);
}
