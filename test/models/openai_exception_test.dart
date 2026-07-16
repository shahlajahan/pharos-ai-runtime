import 'package:pharos_ai_runtime/models/model_exception.dart';
import 'package:pharos_ai_runtime/models/openai_exception.dart';
import 'package:test/test.dart';

void main() {
  test('OpenAIException is a ModelException', () {
    const exception = OpenAIException('boom');

    expect(exception, isA<ModelException>());
  });

  test('OpenAIException preserves the given message', () {
    const exception = OpenAIException('rate limit exceeded');

    expect(exception.message, 'rate limit exceeded');
  });

  test('OpenAIException.toString() is unchanged', () {
    const exception = OpenAIException('rate limit exceeded');

    expect(exception.toString(), 'rate limit exceeded');
  });
}
