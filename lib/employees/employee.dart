import 'package:pharos_ai_runtime/core/result.dart';

abstract class Employee {
  String get id;

  Future<Result> execute();
}
