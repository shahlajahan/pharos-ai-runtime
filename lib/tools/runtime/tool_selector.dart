import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_request.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';

/// Finds every Tool matching a ToolRequest and deterministically scores
/// them by capability coverage, availability, priority, cost, and
/// latency, returning the single best match (or a fallback candidate if
/// the best one is later rejected). Never random.
class ToolSelector {
  const ToolSelector();

  /// Every eligible, capability-matching Tool for [request], best match
  /// first. Callers that need a fallback (for example when the top
  /// choice fails validation) can move on to the next candidate.
  List<Tool> rank(ToolRequest request, List<Tool> tools) {
    final candidates = [
      for (final tool in tools)
        if (_isEligible(tool) && _capabilityScore(tool, request) > 0) tool,
    ];

    final sorted = [...candidates]
      ..sort((a, b) {
        final byCapability = _capabilityScore(
          b,
          request,
        ).compareTo(_capabilityScore(a, request));
        if (byCapability != 0) return byCapability;

        final byAvailability = _availabilityRank(
          a.status,
        ).compareTo(_availabilityRank(b.status));
        if (byAvailability != 0) return byAvailability;

        final byPriority = _priorityOf(b).compareTo(_priorityOf(a));
        if (byPriority != 0) return byPriority;

        final byCost = _costOf(a).compareTo(_costOf(b));
        if (byCost != 0) return byCost;

        return _latencyOf(a).compareTo(_latencyOf(b));
      });

    return sorted;
  }

  /// The single best Tool for [request], or null when none match.
  Tool? select(ToolRequest request, List<Tool> tools) {
    final ranked = rank(request, tools);
    return ranked.isEmpty ? null : ranked.first;
  }

  bool _isEligible(Tool tool) =>
      tool.status == ToolStatus.available || tool.status == ToolStatus.busy;

  double _capabilityScore(Tool tool, ToolRequest request) {
    if (request.requestedCapabilities.isEmpty) {
      return 1.0;
    }
    final matched = request.requestedCapabilities
        .where(tool.capabilities.contains)
        .length;
    return matched / request.requestedCapabilities.length;
  }

  int _availabilityRank(ToolStatus status) => switch (status) {
    ToolStatus.available => 0,
    ToolStatus.busy => 1,
    ToolStatus.offline => 2,
    ToolStatus.disabled => 3,
  };

  /// Read from metadata['priority'] (higher is preferred), defaulting
  /// to 0 when absent.
  num _priorityOf(Tool tool) => (tool.metadata['priority'] as num?) ?? 0;

  /// Read from metadata['cost'] (lower is preferred), defaulting to 0
  /// (free) when absent.
  num _costOf(Tool tool) => (tool.metadata['cost'] as num?) ?? 0;

  /// Read from metadata['latencyMs'] (lower is preferred), defaulting
  /// to 0 when absent.
  num _latencyOf(Tool tool) => (tool.metadata['latencyMs'] as num?) ?? 0;
}
