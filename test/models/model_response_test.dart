import 'package:pharos_ai_runtime/models/model_response.dart';
import 'package:pharos_ai_runtime/tooling/tool_call.dart';
import 'package:test/test.dart';

void main() {
  test('ModelResponse stores text', () {
    const response = ModelResponse(text: 'Paris is the capital of France.');

    expect(response.text, 'Paris is the capital of France.');
  });

  test('ModelResponse is immutable', () {
    const a = ModelResponse(text: 'Paris is the capital of France.');
    const b = ModelResponse(text: 'Paris is the capital of France.');

    // Two const instances with equal field values are canonicalized to the
    // same object by Dart, which is only possible because the constructor
    // is const and the field is final.
    expect(identical(a, b), isTrue);
  });

  test('ModelResponse defaults toolCalls to an empty list', () {
    const response = ModelResponse(text: 'Paris is the capital of France.');

    expect(response.toolCalls, isEmpty);
  });

  test('ModelResponse preserves the given toolCalls', () {
    const toolCalls = [
      ToolCall(id: 'call_1', name: 'search', arguments: '{"query":"Paris"}'),
    ];
    const response = ModelResponse(
      text: 'Paris is the capital of France.',
      toolCalls: toolCalls,
    );

    expect(response.toolCalls, toolCalls);
  });

  test('ModelResponse can be constructed as a const value with toolCalls', () {
    const response = ModelResponse(
      text: 'Paris is the capital of France.',
      toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
    );

    expect(response, isA<ModelResponse>());
  });

  test('ModelResponse equality (via const canonicalization) includes '
      'toolCalls', () {
    const a = ModelResponse(
      text: 'Paris is the capital of France.',
      toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
    );
    const b = ModelResponse(
      text: 'Paris is the capital of France.',
      toolCalls: [ToolCall(id: 'call_1', name: 'search', arguments: '{}')],
    );
    const c = ModelResponse(
      text: 'Paris is the capital of France.',
      toolCalls: [ToolCall(id: 'call_2', name: 'search', arguments: '{}')],
    );

    // Const instances only canonicalize to the same object when every field,
    // including toolCalls, is deeply const-equal.
    expect(identical(a, b), isTrue);
    expect(identical(a, c), isFalse);
  });
}
