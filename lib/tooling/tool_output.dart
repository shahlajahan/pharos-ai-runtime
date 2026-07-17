class ToolOutput {
  const ToolOutput({
    required this.toolCallId,
    required this.toolName,
    required this.success,
    required this.content,
  });

  final String toolCallId;
  final String toolName;
  final bool success;
  final String content;
}
