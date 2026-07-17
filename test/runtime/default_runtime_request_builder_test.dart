import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/knowledge/knowledge_definition.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:test/test.dart';

String _systemPrompt(ModelRequest request) =>
    (request.conversation.messages[0] as SystemMessage).content;

String _userPrompt(ModelRequest request) =>
    (request.conversation.messages[1] as UserMessage).content;

void main() {
  test(
    'build() returns a systemPrompt containing the employee name and role',
    () {
      final builder = DefaultRuntimeRequestBuilder();
      const employee = EmployeeRuntime(
        definition: EmployeeDefinition(
          id: 'marketing',
          name: 'Marketing Employee',
          role: 'Marketing',
        ),
        knowledge: [],
        prompts: [],
      );

      final request = builder.build(employee);

      expect(_systemPrompt(request), contains('Marketing Employee'));
      expect(_systemPrompt(request), contains('Marketing'));
    },
  );

  test('build() includes every prompt content', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [
        PromptDefinition(id: 'a', content: 'First prompt content.'),
        PromptDefinition(id: 'b', content: 'Second prompt content.'),
      ],
    );

    final request = builder.build(employee);

    expect(_systemPrompt(request), contains('First prompt content.'));
    expect(_systemPrompt(request), contains('Second prompt content.'));
  });

  test('build() preserves the order of multiple prompts', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [
        PromptDefinition(id: 'a', content: 'First prompt content.'),
        PromptDefinition(id: 'b', content: 'Second prompt content.'),
      ],
    );

    final request = builder.build(employee);

    expect(
      _systemPrompt(request).indexOf('First prompt content.'),
      lessThan(_systemPrompt(request).indexOf('Second prompt content.')),
    );
  });

  test('build() includes every knowledge content', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [
        KnowledgeDefinition(
          id: 'a',
          title: 'Onboarding',
          content: 'First knowledge content.',
        ),
        KnowledgeDefinition(
          id: 'b',
          title: 'Playbook',
          content: 'Second knowledge content.',
        ),
      ],
      prompts: [],
    );

    final request = builder.build(employee);

    expect(_systemPrompt(request), contains('First knowledge content.'));
    expect(_systemPrompt(request), contains('Second knowledge content.'));
  });

  test('build() preserves the order of multiple knowledge documents', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [
        KnowledgeDefinition(
          id: 'a',
          title: 'Onboarding',
          content: 'First knowledge content.',
        ),
        KnowledgeDefinition(
          id: 'b',
          title: 'Playbook',
          content: 'Second knowledge content.',
        ),
      ],
      prompts: [],
    );

    final request = builder.build(employee);

    expect(
      _systemPrompt(request).indexOf('First knowledge content.'),
      lessThan(_systemPrompt(request).indexOf('Second knowledge content.')),
    );
  });

  test('build() places prompts before knowledge, with header first', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [
        KnowledgeDefinition(
          id: 'k',
          title: 'Onboarding',
          content: 'Knowledge content.',
        ),
      ],
      prompts: [PromptDefinition(id: 'p', content: 'Prompt content.')],
    );

    final request = builder.build(employee);

    final headerIndex = _systemPrompt(request).indexOf('Marketing Employee');
    final promptIndex = _systemPrompt(request).indexOf('Prompt content.');
    final knowledgeIndex = _systemPrompt(request).indexOf('Knowledge content.');

    expect(headerIndex, lessThan(promptIndex));
    expect(promptIndex, lessThan(knowledgeIndex));
  });

  test('build() emits only the header followed by the knowledge section '
      'when there are no prompts', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [
        KnowledgeDefinition(
          id: 'k',
          title: 'Onboarding',
          content: 'Knowledge content.',
        ),
      ],
      prompts: [],
    );

    final request = builder.build(employee);

    expect(
      _systemPrompt(request),
      'You are Marketing Employee.\nYour role is Marketing.\n\n'
      'Knowledge content.',
    );
  });

  test('build() emits only the header followed by the prompt section '
      'when there is no knowledge', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [PromptDefinition(id: 'p', content: 'Prompt content.')],
    );

    final request = builder.build(employee);

    expect(
      _systemPrompt(request),
      'You are Marketing Employee.\nYour role is Marketing.\n\n'
      'Prompt content.',
    );
  });

  test('build() emits only the header when there are no prompts and no '
      'knowledge', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );

    final request = builder.build(employee);

    expect(
      _systemPrompt(request),
      'You are Marketing Employee.\nYour role is Marketing.',
    );
  });

  test('build() returns an empty userPrompt', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [
        KnowledgeDefinition(
          id: 'k',
          title: 'Onboarding',
          content: 'Knowledge content.',
        ),
      ],
      prompts: [PromptDefinition(id: 'a', content: 'Prompt content.')],
    );

    final request = builder.build(employee);

    expect(_userPrompt(request), '');
  });

  test('build() works for different employees', () {
    final builder = DefaultRuntimeRequestBuilder();
    const engineering = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'engineering',
        name: 'Engineering Employee',
        role: 'Engineering',
      ),
      knowledge: [
        KnowledgeDefinition(
          id: 'k',
          title: 'Runbook',
          content: 'Ship reliable systems.',
        ),
      ],
      prompts: [PromptDefinition(id: 'a', content: 'Ship quality code.')],
    );

    final request = builder.build(engineering);

    expect(_systemPrompt(request), contains('Engineering Employee'));
    expect(_systemPrompt(request), contains('Engineering'));
    expect(_systemPrompt(request), contains('Ship quality code.'));
    expect(_systemPrompt(request), contains('Ship reliable systems.'));
    expect(_userPrompt(request), '');
  });

  test('build() defaults to an empty tool list when none is provided', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );

    final request = builder.build(employee);

    expect(request.tools, isEmpty);
  });

  test('build() forwards the given tools unchanged', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [],
    );
    const tools = [
      ToolDefinition(id: 'search', description: 'Search the web.'),
      ToolDefinition(id: 'calculator', description: 'Evaluate math.'),
    ];

    final request = builder.build(employee, tools: tools);

    expect(request.tools, same(tools));
  });
}
