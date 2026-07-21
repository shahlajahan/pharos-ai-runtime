import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';

/// One request to execute something via the Tool Runtime. Immutable;
/// carries no implementation logic itself — it only describes what is
/// being asked for.
class ToolRequest {
  const ToolRequest({
    required this.taskId,
    required this.requestedCapabilities,
    required this.operation,
    required this.parameters,
    required this.timeout,
    required this.metadata,
  });

  final String taskId;
  final Set<ToolCapability> requestedCapabilities;
  final String operation;
  final Map<String, Object> parameters;
  final Duration timeout;
  final Map<String, Object> metadata;
}
