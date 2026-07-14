import 'context.dart';

abstract class Agent {
  String get id;

  Future<void> run(ExecutionContext context);
}