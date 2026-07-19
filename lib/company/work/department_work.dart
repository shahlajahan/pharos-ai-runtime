import 'package:pharos_ai_runtime/company/departments/department.dart';
import 'package:pharos_ai_runtime/company/work/work.dart';

/// Links a Department to the Work it does.
class DepartmentWork {
  const DepartmentWork({required this.department, required this.work});

  final Department department;
  final Work work;
}
