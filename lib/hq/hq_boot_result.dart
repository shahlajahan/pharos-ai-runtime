import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/runtime/employee_runtime.dart';

class HQBootResult {
  const HQBootResult({required this.result, required this.employees});

  final Result result;
  final List<EmployeeRuntime> employees;
}
