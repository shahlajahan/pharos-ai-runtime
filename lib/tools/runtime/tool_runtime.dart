import 'package:pharos_ai_runtime/tools/models/tool_request.dart';
import 'package:pharos_ai_runtime/tools/models/tool_result.dart';
import 'package:pharos_ai_runtime/tools/registry/tool_registry.dart';
import 'package:pharos_ai_runtime/tools/runtime/tool_selector.dart';
import 'package:pharos_ai_runtime/tools/runtime/tool_validator.dart';

/// Validates a ToolRequest, selects the best matching Tool (falling
/// back to the next-ranked candidate if the best one fails validation),
/// invokes it, and returns a normalized ToolResult. Knows tools,
/// capabilities, validation, and invocation only — never workflows,
/// business rules, marketing, finance, or products.
///
/// No concrete Tool implementation exists yet (Tool is data only, with
/// no execution state or execute() method), so "invoke" never calls an
/// external system, an LLM, or the filesystem: a validated, selected
/// tool is reported as successfully invoked via a normalized
/// placeholder result. Performing a tool's real work is future
/// execution-engine work.
class ToolRuntime {
  const ToolRuntime({
    required this.registry,
    this.validator = const ToolValidator(),
    this.selector = const ToolSelector(),
  });

  final ToolRegistry registry;
  final ToolValidator validator;
  final ToolSelector selector;

  ToolResult invoke(ToolRequest request) {
    final stopwatch = Stopwatch()..start();
    final candidates = selector.rank(request, registry.list());

    if (candidates.isEmpty) {
      stopwatch.stop();
      return ToolResult(
        success: false,
        output: '',
        structuredData: const {},
        artifacts: const [],
        warnings: const [],
        errors: const ['No tool matches the requested capabilities.'],
        executionTime: stopwatch.elapsed,
      );
    }

    final warnings = <String>[];
    for (final tool in candidates) {
      final validationErrors = validator.validate(tool, request);
      if (validationErrors.isEmpty) {
        stopwatch.stop();
        return ToolResult(
          success: true,
          output:
              'Tool "${tool.id}" invoked for operation '
              '"${request.operation}".',
          structuredData: const {},
          artifacts: const [],
          warnings: warnings,
          errors: const [],
          executionTime: stopwatch.elapsed,
        );
      }
      warnings.add(
        'Tool "${tool.id}" rejected during validation: '
        '${validationErrors.join(' ')}',
      );
    }

    stopwatch.stop();
    return ToolResult(
      success: false,
      output: '',
      structuredData: const {},
      artifacts: const [],
      warnings: warnings,
      errors: const ['No candidate tool passed validation.'],
      executionTime: stopwatch.elapsed,
    );
  }
}
