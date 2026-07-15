import 'package:pharos_ai_runtime/core/result.dart';

abstract class HQLoader {
  Future<Result> load(String path);
}
