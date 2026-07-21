/// A stable, unique identifier for one Tool. A dedicated value object
/// (rather than a bare String) so future compatibility — remote tools,
/// versioned tool identities — can be added without changing Tool's
/// public API.
class ToolId {
  const ToolId(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is ToolId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
