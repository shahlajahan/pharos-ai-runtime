import 'package:pharos_ai_runtime/models/openai_result.dart';
import 'package:test/test.dart';

void main() {
  test('OpenAIResult stores text', () {
    const result = OpenAIResult(text: 'Paris is the capital of France.');

    expect(result.text, 'Paris is the capital of France.');
  });

  test('OpenAIResult is immutable', () {
    const a = OpenAIResult(text: 'Paris is the capital of France.');
    const b = OpenAIResult(text: 'Paris is the capital of France.');

    // Two const instances with equal field values are canonicalized to the
    // same object by Dart, which is only possible because the constructor
    // is const and the field is final.
    expect(identical(a, b), isTrue);
  });
}
