import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/tooling/tool_definition.dart';
import 'package:test/test.dart';

void main() {
  test('ModelRequest stores systemPrompt and userPrompt', () {
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );

    expect(request.systemPrompt, 'You are a helpful assistant.');
    expect(request.userPrompt, 'What is the capital of France?');
  });

  test('ModelRequest defaults to an empty tool list', () {
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );

    expect(request.tools, isEmpty);
  });

  test('ModelRequest preserves the given tool definitions', () {
    const tools = [
      ToolDefinition(id: 'search', description: 'Search the web.'),
      ToolDefinition(id: 'calculator', description: 'Evaluate math.'),
    ];
    const request = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
      tools: tools,
    );

    expect(request.tools, tools);
  });

  test('ModelRequest is immutable', () {
    const a = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );
    const b = ModelRequest(
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: 'What is the capital of France?',
    );

    // Two const instances with equal field values are canonicalized to the
    // same object by Dart, which is only possible because the constructor
    // is const and every field is final.
    expect(identical(a, b), isTrue);
  });
}
