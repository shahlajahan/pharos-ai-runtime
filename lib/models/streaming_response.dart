import 'package:pharos_ai_runtime/tooling/tool_call.dart';

abstract interface class StreamingResponse {
  Stream<ModelResponseChunk> get stream;
}

class ModelResponseChunk {
  const ModelResponseChunk({
    this.textDelta,
    this.toolCalls,
    this.isFinished = false,
  });

  final String? textDelta;
  final List<ToolCall>? toolCalls;
  final bool isFinished;
}
