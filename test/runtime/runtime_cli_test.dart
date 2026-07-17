import 'dart:io';

import 'package:pharos_ai_runtime/core/result.dart';
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
import 'package:pharos_ai_runtime/models/mock_model_provider.dart';
import 'package:pharos_ai_runtime/models/model_provider_resolver.dart';
import 'package:pharos_ai_runtime/models/model_registry.dart';
import 'package:pharos_ai_runtime/models/openai_environment.dart';
import 'package:pharos_ai_runtime/models/openai_provider.dart';
import 'package:pharos_ai_runtime/models/openai_provider_factory.dart';
import 'package:pharos_ai_runtime/prompts/markdown_prompt_parser.dart';
import 'package:pharos_ai_runtime/prompts/prompt_repository.dart';
import 'package:pharos_ai_runtime/runtime/default_employee_response_handler.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_factory.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';
import 'package:pharos_ai_runtime/runtime/runtime_runner.dart';
import 'package:test/test.dart';

const _openAiEnvironment = OpenAIEnvironment(
  apiKey: 'sk-test-key',
  baseUrl: 'https://api.openai.com/v1/chat/completions',
  model: 'gpt-4',
  temperature: 0.7,
);

class _FakeRuntime extends Runtime {
  _FakeRuntime()
    : super(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
      );

  List<String>? capturedArgs;
  HQSource? capturedSource;
  Result? result = Result.success('fake result');

  @override
  Future<Result?> run(List<String> args, {HQSource? source}) async {
    capturedArgs = args;
    capturedSource = source;

    return result;
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
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('runtime_cli_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'Runtime returns a successful Result when --hq points to a valid HQ',
    () async {
      final employeeDir = Directory('${tempDir.path}/employees/marketing');
      employeeDir.createSync(recursive: true);
      File('${employeeDir.path}/employee.md').writeAsStringSync('''
id: marketing
name: Marketing Employee
role: Marketing
''');
      Directory('${employeeDir.path}/knowledge').createSync();
      Directory('${employeeDir.path}/prompts').createSync();
      Directory('${tempDir.path}/knowledge').createSync();
      Directory('${tempDir.path}/prompts').createSync();

      final runtime = Runtime(
        modelProvider: MockModelProvider(),
        requestBuilder: DefaultRuntimeRequestBuilder(),
        responseHandler: DefaultEmployeeResponseHandler(),
        bootstrap: _realBootstrap(),
      );

      final result = await runtime.run([
        'marketing',
      ], source: LocalHQSource(tempDir.path));

      expect(result, isNotNull);
      expect(result!.success, isTrue);
    },
  );

  test('Runtime returns Result.failure without executing the Agent '
      'when --hq points to an invalid HQ', () async {
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
      bootstrap: _realBootstrap(),
    );

    final result = await runtime.run([
      'marketing',
    ], source: LocalHQSource('${tempDir.path}/does-not-exist'));

    expect(result, isNotNull);
    expect(result!.success, isFalse);
  });

  test('Runtime behaves normally when --hq is not provided', () async {
    final runtime = Runtime(
      modelProvider: MockModelProvider(),
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.run(['marketing']);

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test('Default production wiring resolves "mock" to MockModelProvider and '
      'Runtime starts normally', () async {
    final registry = ModelRegistry(providers: {'mock': MockModelProvider()});

    final provider = ModelProviderResolver.resolve(
      provider: 'mock',
      registry: registry,
    );

    expect(provider, isA<MockModelProvider>());

    final runtime = Runtime(
      modelProvider: provider,
      requestBuilder: DefaultRuntimeRequestBuilder(),
      responseHandler: DefaultEmployeeResponseHandler(),
    );

    final result = await runtime.run(['marketing']);

    expect(result, isNotNull);
    expect(result!.success, isTrue);
  });

  test('Production wiring resolves "openai" to an OpenAIProvider '
      'successfully without performing any HTTP request', () {
    final registry = ModelRegistry(
      providers: {'openai': OpenAIProviderFactory().build(_openAiEnvironment)},
    );

    final provider = ModelProviderResolver.resolve(
      provider: 'openai',
      registry: registry,
    );

    expect(provider, isA<OpenAIProvider>());
  });

  test('RuntimeRunner forwards args unchanged', () async {
    final fakeRuntime = _FakeRuntime();
    final runner = RuntimeRunner(runtime: fakeRuntime);
    final args = ['marketing'];

    await runner.run(args: args);

    expect(fakeRuntime.capturedArgs, same(args));
  });

  test('RuntimeRunner forwards source unchanged', () async {
    final fakeRuntime = _FakeRuntime();
    final runner = RuntimeRunner(runtime: fakeRuntime);
    final source = LocalHQSource(tempDir.path);

    await runner.run(args: const ['marketing'], source: source);

    expect(fakeRuntime.capturedSource, same(source));
  });

  test('RuntimeRunner returns exactly Runtime.run()\'s Result', () async {
    final fakeRuntime = _FakeRuntime();
    final runner = RuntimeRunner(runtime: fakeRuntime);

    final result = await runner.run(args: const ['marketing']);

    expect(result, same(fakeRuntime.result));
  });
}
