import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';

class StreamingResponseAggregator {
  Future<ModelResponse> aggregate(StreamingResponse streamingResponse) async {
    final textBuffer = StringBuffer();
    final toolCalls = <ToolCall>[];

    await for (final chunk in streamingResponse.stream) {
      if (chunk.textDelta != null) {
        textBuffer.write(chunk.textDelta);
      }

      if (chunk.toolCalls != null) {
        toolCalls.addAll(chunk.toolCalls!);
      }

      if (chunk.isFinished) {
        break;
      }
    }

    return ModelResponse(text: textBuffer.toString(), toolCalls: toolCalls);
  }
}
