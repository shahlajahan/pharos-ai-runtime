import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';
import 'package:pharos_ai_runtime/runtime/runtime.dart';

class RuntimeRunner {
  RuntimeRunner({required Runtime runtime}) : _runtime = runtime;

  final Runtime _runtime;

  Future<Result?> run({required List<String> args, HQSource? source}) {
    return _runtime.run(args, source: source);
  }
}
