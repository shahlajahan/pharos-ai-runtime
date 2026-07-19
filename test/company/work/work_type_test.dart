import 'package:pharos_ai_runtime/company/work/work_type.dart';
import 'package:test/test.dart';

void main() {
  test('WorkType has one value per kind of work', () {
    expect(WorkType.values, [
      WorkType.engineering,
      WorkType.marketing,
      WorkType.finance,
      WorkType.sales,
      WorkType.support,
    ]);
  });
}
