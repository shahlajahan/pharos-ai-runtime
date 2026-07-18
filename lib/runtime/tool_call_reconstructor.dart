import 'package:pharos_ai_runtime/models/streaming_response.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';

/// Accumulates streaming ToolCall fragments (as they arrive across
/// successive [ModelResponseChunk]s) into complete [ToolCall]s.
///
/// A fragment with a non-empty [ToolCall.id] starts (or, if the id repeats,
/// continues) that ToolCall. A fragment with an empty id is a continuation
/// of whichever ToolCall id was most recently seen — this mirrors how
/// streaming providers send the id/name only on a ToolCall's first
/// fragment and stream only `arguments` slices afterward.
class ToolCallReconstructor {
  final List<String> _order = [];
  final Map<String, StringBuffer> _arguments = {};
  final Map<String, String> _names = {};
  String? _lastId;

  void observe(ModelResponseChunk chunk) {
    final fragments = chunk.toolCalls;

    if (fragments == null) {
      return;
    }

    for (final fragment in fragments) {
      if (fragment.id.isNotEmpty) {
        if (!_arguments.containsKey(fragment.id)) {
          _order.add(fragment.id);
          _arguments[fragment.id] = StringBuffer();
          _names[fragment.id] = '';
        }

        _arguments[fragment.id]!.write(fragment.arguments);

        if (fragment.name.isNotEmpty) {
          _names[fragment.id] = fragment.name;
        }

        _lastId = fragment.id;
      } else if (_lastId != null) {
        _arguments[_lastId]!.write(fragment.arguments);

        if (fragment.name.isNotEmpty) {
          _names[_lastId!] = fragment.name;
        }
      }
    }
  }

  List<ToolCall> complete() {
    return [
      for (final id in _order)
        ToolCall(
          id: id,
          name: _names[id] ?? '',
          arguments: _arguments[id]!.toString(),
        ),
    ];
  }
}
