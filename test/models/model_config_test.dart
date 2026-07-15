import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:test/test.dart';

void main() {
  test('ModelConfig stores model', () {
    const config = ModelConfig(model: 'claude-sonnet-5', temperature: 0.7);

    expect(config.model, 'claude-sonnet-5');
  });

  test('ModelConfig stores temperature', () {
    const config = ModelConfig(model: 'claude-sonnet-5', temperature: 0.7);

    expect(config.temperature, 0.7);
  });

  test('ModelConfig is immutable', () {
    const a = ModelConfig(model: 'claude-sonnet-5', temperature: 0.7);
    const b = ModelConfig(model: 'claude-sonnet-5', temperature: 0.7);

    // Two const instances with equal field values are canonicalized to the
    // same object by Dart, which is only possible because the constructor
    // is const and every field is final.
    expect(identical(a, b), isTrue);
  });
}
