import 'package:pharos_ai_runtime/company/departments/engineering_department.dart';
import 'package:pharos_ai_runtime/company/work/department_work.dart';
import 'package:pharos_ai_runtime/company/work/work.dart';
import 'package:test/test.dart';

class _FakeWork implements Work {
  @override
  String get id => 'w1';

  @override
  String get title => 'Design the API';
}

void main() {
  test('DepartmentWork links a Department to the Work it does', () {
    final work = _FakeWork();
    final departmentWork = DepartmentWork(
      department: const EngineeringDepartment(),
      work: work,
    );

    expect(departmentWork.department, const EngineeringDepartment());
    expect(departmentWork.work, same(work));
  });
}
