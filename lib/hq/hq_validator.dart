import 'dart:io';

import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';

class HQValidator {
  Future<Result> validate(HQSource source) async {
    final rootPath = await source.rootPath();

    if (!await Directory(rootPath).exists()) {
      return Result.failure('HQ root directory does not exist: $rootPath');
    }

    if (!await Directory('$rootPath/employees').exists()) {
      return Result.failure('HQ is missing required directory: employees/');
    }

    if (!await Directory('$rootPath/knowledge').exists()) {
      return Result.failure('HQ is missing required directory: knowledge/');
    }

    return Result.success('HQ structure is valid: $rootPath');
  }
}
