import 'package:pharos_ai_runtime/company/metrics/metrics.dart';
import 'package:test/test.dart';

void main() {
  test('Metrics can be instantiated as an empty placeholder aggregate', () {
    const metrics = Metrics();

    expect(metrics, isNotNull);
  });
}
