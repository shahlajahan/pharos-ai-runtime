import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/prompts/prompt_definition.dart';
import 'package:pharos_ai_runtime/runtime/default_runtime_request_builder.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

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

      expect(request.systemPrompt, contains('Marketing Employee'));
      expect(request.systemPrompt, contains('Marketing'));
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

    expect(request.systemPrompt, contains('First prompt content.'));
    expect(request.systemPrompt, contains('Second prompt content.'));
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
      request.systemPrompt.indexOf('First prompt content.'),
      lessThan(request.systemPrompt.indexOf('Second prompt content.')),
    );
  });

  test(
    'build() emits only the name/role section when there are no prompts',
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

      expect(
        request.systemPrompt,
        'You are Marketing Employee.\nYour role is Marketing.',
      );
    },
  );

  test('build() returns an empty userPrompt', () {
    final builder = DefaultRuntimeRequestBuilder();
    const employee = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'marketing',
        name: 'Marketing Employee',
        role: 'Marketing',
      ),
      knowledge: [],
      prompts: [PromptDefinition(id: 'a', content: 'Prompt content.')],
    );

    final request = builder.build(employee);

    expect(request.userPrompt, '');
  });

  test('build() works for different employees', () {
    final builder = DefaultRuntimeRequestBuilder();
    const engineering = EmployeeRuntime(
      definition: EmployeeDefinition(
        id: 'engineering',
        name: 'Engineering Employee',
        role: 'Engineering',
      ),
      knowledge: [],
      prompts: [PromptDefinition(id: 'a', content: 'Ship quality code.')],
    );

    final request = builder.build(engineering);

    expect(request.systemPrompt, contains('Engineering Employee'));
    expect(request.systemPrompt, contains('Engineering'));
    expect(request.systemPrompt, contains('Ship quality code.'));
    expect(request.userPrompt, '');
  });
}
