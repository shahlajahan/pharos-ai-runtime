import 'package:pharos_ai_runtime/runtime/intent/runtime_intent.dart';

/// Pure data: carries one RuntimeIntent across the Company/Runtime
/// boundary.
class RuntimeIntentRequest {
  const RuntimeIntentRequest({required this.intent});

  final RuntimeIntent intent;
}
