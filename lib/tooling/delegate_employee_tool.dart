import 'dart:convert';

import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/hq/hq.dart';
import 'package:pharos_ai_runtime/tooling/tool.dart';
import 'package:pharos_ai_runtime/tooling/tool_context.dart';

/// The first HQ-native Tool: lets an Employee delegate work to another
/// Employee by asking HQ to invoke it.
///
/// Arguments: `{"employee": "...", "goal": "..."}`.
///
/// Supports exactly one level of delegation. If the delegated Employee's
/// own tool-calling loop calls this same tool again before this call
/// returns, that nested call is rejected — nested delegation is not
/// supported yet.
class DelegateEmployeeTool extends Tool {
  /// [hq] is a provider rather than an [HQ] instance directly, since the HQ
  /// that owns this tool's ToolRegistry cannot exist yet at the point this
  /// tool is constructed (the ToolRegistry is itself required to construct
  /// that HQ). The provider is only called once execute() actually runs,
  /// by which point the owning HQ is fully constructed.
  DelegateEmployeeTool({required HQ Function() hq}) : _hqProvider = hq;

  final HQ Function() _hqProvider;
  bool _isDelegating = false;

  @override
  String get id => 'delegate_employee';

  @override
  Future<Result> execute(ToolContext context) async {
    if (_isDelegating) {
      return Result.failure(
        'Nested delegation is not supported yet: "delegate_employee" was '
        'called while another delegation was already in progress.',
      );
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(context.arguments);
    } on FormatException {
      return Result.failure(
        'Invalid "delegate_employee" arguments: not valid JSON.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return Result.failure(
        'Invalid "delegate_employee" arguments: expected a JSON object.',
      );
    }

    final employee = decoded['employee'];
    final goal = decoded['goal'];

    if (employee is! String || employee.isEmpty) {
      return Result.failure(
        'Invalid "delegate_employee" arguments: "employee" is required.',
      );
    }

    if (goal is! String || goal.isEmpty) {
      return Result.failure(
        'Invalid "delegate_employee" arguments: "goal" is required.',
      );
    }

    _isDelegating = true;

    try {
      return await _hqProvider().invoke(employee: employee, goal: goal);
    } finally {
      _isDelegating = false;
    }
  }
}
