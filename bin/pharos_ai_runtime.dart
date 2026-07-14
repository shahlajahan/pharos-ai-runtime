import 'package:pharos_ai_runtime/runtime/runtime.dart';

Future<void> main(List<String> args) async {
  final runtime = Runtime();

  await runtime.run(args);
}