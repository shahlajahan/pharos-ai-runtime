import 'package:pharos_ai_runtime/agents/models/agent_id.dart';
import 'package:pharos_ai_runtime/agents/models/agent_status.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:pharos_ai_runtime/tasks/models/task_priority.dart';

/// One autonomous worker, represented purely as data for discovery and
/// assignment. Immutable: no execution logic, no tool knowledge —
/// actually running a Task is entirely the responsibility of a future
/// execution engine. [priority] reuses [TaskPriority] rather than a
/// separate enum, since an Agent's priority is only ever compared
/// against the Tasks it is being matched to.
///
/// Distinct from the unrelated `Agent` abstract class in
/// `lib/core/agent.dart` (the Runtime's execution-pipeline entry point
/// that `DailyAgent`/`MarketingAgent` extend). The two coexist under
/// different import paths; this one is a value object with no `run()`
/// method at all.
class Agent {
  const Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.capabilities,
    required this.priority,
    required this.metadata,
  });

  final AgentId id;
  final String name;
  final String description;
  final AgentStatus status;
  final CapabilitySet capabilities;
  final TaskPriority priority;
  final Map<String, Object> metadata;
}
