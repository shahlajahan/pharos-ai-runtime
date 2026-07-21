/// The normalized outcome of one ToolRuntime.invoke() call — the same
/// shape regardless of which Tool was actually selected.
class ToolResult {
  const ToolResult({
    required this.success,
    required this.output,
    required this.structuredData,
    required this.artifacts,
    required this.warnings,
    required this.errors,
    required this.executionTime,
  });

  final bool success;
  final String output;
  final Map<String, Object> structuredData;

  /// Identifiers or paths for anything the tool produced (for example
  /// generated file names).
  final List<String> artifacts;

  final List<String> warnings;
  final List<String> errors;
  final Duration executionTime;
}
