/// Exactly one capability a Tool provides (for example "file-read",
/// "web-search", "image-generation"). A plain value object — distinct
/// from the Agent-level `Capability` in
/// `lib/agents/models/capability.dart`, since tool capabilities and
/// agent capabilities are matched independently by their own runtimes.
class ToolCapability {
  const ToolCapability(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is ToolCapability && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
