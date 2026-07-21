/// One Tool's current availability. Mirrors AgentStatus's shape, since
/// Tool Runtime's discovery/selection concerns are directly analogous
/// to Agent Runtime's.
enum ToolStatus { available, busy, offline, disabled }
