import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_request.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';

/// Deterministically checks whether a Tool can honor a ToolRequest:
/// existence, capability coverage, a supported operation, availability
/// (permission to be used), and a positive timeout. No AI, no workflow
/// logic — purely structural checks over already-known data. Returns
/// an empty list when the request is valid.
class ToolValidator {
  const ToolValidator();

  List<String> validate(Tool? tool, ToolRequest request) {
    if (tool == null) {
      return const ['Tool does not exist.'];
    }

    final errors = <String>[];

    final missingCapabilities = request.requestedCapabilities
        .where((capability) => !tool.capabilities.contains(capability))
        .toList();
    if (missingCapabilities.isNotEmpty) {
      errors.add(
        'Tool "${tool.id}" does not support: '
        '${missingCapabilities.join(', ')}.',
      );
    }

    if (!tool.supportedOperations.contains(request.operation)) {
      errors.add(
        'Tool "${tool.id}" does not support operation '
        '"${request.operation}".',
      );
    }

    if (tool.status == ToolStatus.disabled) {
      errors.add('Tool "${tool.id}" is disabled.');
    }

    if (request.timeout <= Duration.zero) {
      errors.add('Request timeout must be greater than zero.');
    }

    return errors;
  }
}
