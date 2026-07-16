import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

const _marketingDefinition = EmployeeDefinition(
  id: 'marketing',
  name: 'Marketing Employee',
  role: 'Marketing',
);

const _engineeringDefinition = EmployeeDefinition(
  id: 'engineering',
  name: 'Engineering Employee',
  role: 'Engineering',
);

void main() {
  test('HQBootResult stores the result', () {
    final result = Result.success('booted');

    final bootResult = HQBootResult(result: result, employees: const []);

    expect(bootResult.result, same(result));
  });

  test('HQBootResult stores the employees', () {
    const employee = EmployeeRuntime(
      definition: _marketingDefinition,
      knowledge: [],
      prompts: [],
    );

    final bootResult = HQBootResult(
      result: Result.success('booted'),
      employees: const [employee],
    );

    expect(bootResult.employees, [employee]);
  });

  test('HQBootResult supports an empty employee list', () {
    final bootResult = HQBootResult(
      result: Result.success('booted'),
      employees: const [],
    );

    expect(bootResult.employees, isEmpty);
  });

  test('HQBootResult supports multiple EmployeeRuntime objects', () {
    const marketing = EmployeeRuntime(
      definition: _marketingDefinition,
      knowledge: [],
      prompts: [],
    );
    const engineering = EmployeeRuntime(
      definition: _engineeringDefinition,
      knowledge: [],
      prompts: [],
    );

    final bootResult = HQBootResult(
      result: Result.success('booted'),
      employees: const [marketing, engineering],
    );

    expect(bootResult.employees, hasLength(2));
    expect(bootResult.employees, [marketing, engineering]);
  });
}
