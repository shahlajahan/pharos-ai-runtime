/// A stable, unique identifier for one Execution. A dedicated value
/// object (rather than a bare String) so future compatibility —
/// distributed execution, persistent execution, checkpoint resume —
/// can be added without changing Execution's public API.
class ExecutionId {
  const ExecutionId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ExecutionId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
