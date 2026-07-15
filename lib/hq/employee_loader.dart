import 'dart:io';

import 'package:pharos_ai_runtime/hq/hq_source.dart';

class EmployeeLoader {
  Future<Directory?> load(HQSource source, String employeeId) async {
    final rootPath = await source.rootPath();
    final employeeDirectory = Directory('$rootPath/employees/$employeeId');

    if (!await employeeDirectory.exists()) {
      return null;
    }

    return employeeDirectory;
  }
}
