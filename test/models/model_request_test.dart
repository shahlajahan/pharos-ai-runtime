import 'package:pharos_ai_runtime/models/model_request.dart';
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
