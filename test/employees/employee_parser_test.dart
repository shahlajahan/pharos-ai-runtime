import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/employees/employee_parser.dart';
import 'package:test/test.dart';

class _FakeEmployeeParser extends EmployeeParser {
  @override
  Future<EmployeeDefinition> parse(Directory directory) async {
    return const EmployeeDefinition(
      id: 'marketing',
      name: 'Marketing Employee',
      role: 'Marketing',
    );
  }
}

void main() {
  test('EmployeeParser exposes parse(Directory) returning EmployeeDefinition', () async {
    final parser = _FakeEmployeeParser();

    final definition = await parser.parse(Directory('/some/employee/path'));

    expect(definition.id, 'marketing');
    expect(definition.name, 'Marketing Employee');
    expect(definition.role, 'Marketing');
  });
}
