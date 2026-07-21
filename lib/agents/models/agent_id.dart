/// A stable, unique identifier for one Agent. A dedicated value object
/// (rather than a bare String) so future compatibility — remote agents,
/// cloud agents, versioned agent identities — can be added without
/// changing Agent's public API.
class AgentId {
  const AgentId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is AgentId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
