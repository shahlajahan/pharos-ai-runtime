import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/hq/hq_context.dart';
import 'package:pharos_ai_runtime/memory/conversation_memory.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';
import 'package:test/test.dart';

void main() {
  const employee = EmployeeRuntime(
    definition: EmployeeDefinition(
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    ),
    knowledge: [],
    prompts: [],
  );

  test('HQContext stores goal and employee', () {
    final context = HQContext(
      goal: 'Write a LinkedIn post',
      employee: employee,
    );

    expect(context.goal, 'Write a LinkedIn post');
    expect(context.employee, same(employee));
  });

  test('HQContext creates a fresh, empty ConversationMemory automatically '
      'when none is given', () async {
    final context = HQContext(goal: 'Write a post', employee: employee);

    expect(await context.memory.readAll(), isEmpty);
  });

  test('HQContext uses the given ConversationMemory when one is provided', () {
    final memory = ConversationMemory();
    final context = HQContext(
      goal: 'Write a post',
      employee: employee,
      memory: memory,
    );

    expect(context.memory, same(memory));
  });
}
