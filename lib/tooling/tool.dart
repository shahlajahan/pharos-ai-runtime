import 'package:pharos_ai_runtime/core/result.dart';

abstract class Tool {
  String get id;

  Future<Result> execute();
}
