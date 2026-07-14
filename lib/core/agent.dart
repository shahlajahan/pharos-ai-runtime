import 'context.dart';
import 'result.dart';

abstract class Agent {
  String get id;

  Future<Result> run(ExecutionContext context);
}