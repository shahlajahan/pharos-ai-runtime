import 'package:pharos_ai_runtime/core/result.dart';
import 'package:test/test.dart';

void main() {
  test('Result.success carries success flag and message', () {
    final result = Result.success('it worked');

    expect(result.success, isTrue);
    expect(result.message, 'it worked');
  });

  test('Result.failure carries success flag and message', () {
    final result = Result.failure('it failed');

    expect(result.success, isFalse);
    expect(result.message, 'it failed');
  });
}
