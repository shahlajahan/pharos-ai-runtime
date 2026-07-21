import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';

/// One executable capability the Tool Runtime can discover, validate,
/// and select — a plugin's metadata, not a running process. Immutable:
/// no execution state lives here.
///
/// Distinct from the unrelated `Tool` abstract class in
/// `lib/tooling/tool.dart` (the Runtime's execution-pipeline
/// tool-calling interface, `abstract class Tool { execute(ToolContext) }`,
/// still used by `ToolInvoker`). The two coexist under different import
/// paths; this one has no `execute()` method at all — it is pure data.
class Tool {
  const Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.capabilities,
    required this.supportedOperations,
    required this.metadata,
  });

  final ToolId id;
  final String name;
  final String description;
  final ToolStatus status;
  final Set<ToolCapability> capabilities;

  /// The named operations this tool can perform (for example "read",
  /// "commit", "search") — what a ToolRequest.operation must match.
  final List<String> supportedOperations;

  final Map<String, Object> metadata;
}
