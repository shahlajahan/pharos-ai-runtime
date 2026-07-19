import 'package:pharos_ai_runtime/company/departments/department.dart';

/// The part of a Company that owns its Departments. Pure domain
/// structure only — no behavior, no runtime logic.
class Organization {
  const Organization({required this.departments});

  final List<Department> departments;
}
