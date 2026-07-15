import 'package:pharos_ai_runtime/models/model_response.dart';
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
}
