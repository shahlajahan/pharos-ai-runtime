import 'package:pharos_ai_runtime/core/result.dart';

abstract class Memory {
  Future<Result> store();

  Future<Result> retrieve();
}
