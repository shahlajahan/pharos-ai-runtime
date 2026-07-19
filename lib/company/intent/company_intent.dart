import 'package:pharos_ai_runtime/company/intent/intent.dart';
import 'package:pharos_ai_runtime/company/intent/intent_status.dart';
import 'package:pharos_ai_runtime/company/intent/intent_type.dart';

/// Pure data: an Intent paired with its type and current status.
class CompanyIntent {
  const CompanyIntent({
    required this.intent,
    required this.type,
    required this.status,
  });

  final Intent intent;
  final IntentType type;
  final IntentStatus status;
}
