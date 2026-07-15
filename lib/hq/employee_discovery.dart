import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pharos_ai_runtime/hq/hq_source.dart';

class EmployeeDiscovery {
  Future<List<String>> discover(HQSource source) async {
    final rootPath = await source.rootPath();
    final employeesDirectory = Directory('$rootPath/employees');

    if (!await employeesDirectory.exists()) {
      return [];
    }

    final names = <String>[];

    await for (final entity in employeesDirectory.list()) {
      if (entity is! Directory) {
        continue;
      }

      final name = p.basename(entity.path);

      if (name.startsWith('.')) {
        continue;
      }

      names.add(name);
    }

    names.sort();

    return names;
  }
}
