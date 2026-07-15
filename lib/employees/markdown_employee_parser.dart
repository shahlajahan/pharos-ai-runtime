import 'dart:io';

import 'package:pharos_ai_runtime/employees/employee_definition.dart';
import 'package:pharos_ai_runtime/employees/employee_parser.dart';

class MarkdownEmployeeParser extends EmployeeParser {
  @override
  Future<EmployeeDefinition> parse(Directory directory) async {
    final file = File('${directory.path}/employee.md');
    final lines = await file.readAsLines();

    final metadata = <String, String>{};

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        continue;
      }

      final separatorIndex = trimmedLine.indexOf(':');

      if (separatorIndex == -1) {
        continue;
      }

      final key = trimmedLine.substring(0, separatorIndex).trim();
      final value = trimmedLine.substring(separatorIndex + 1).trim();

      metadata[key] = value;
    }

    final id = metadata['id'];
    final name = metadata['name'];
    final role = metadata['role'];

    if (id == null || id.isEmpty) {
      throw const FormatException(
        'employee.md is missing required field "id"',
      );
    }

    if (name == null || name.isEmpty) {
      throw const FormatException(
        'employee.md is missing required field "name"',
      );
    }

    if (role == null || role.isEmpty) {
      throw const FormatException(
        'employee.md is missing required field "role"',
      );
    }

    return EmployeeDefinition(id: id, name: name, role: role);
  }
}
