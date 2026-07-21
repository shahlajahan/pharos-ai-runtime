import 'package:pharos_ai_runtime/tools/models/tool.dart';
import 'package:pharos_ai_runtime/tools/models/tool_capability.dart';
import 'package:pharos_ai_runtime/tools/models/tool_id.dart';
import 'package:pharos_ai_runtime/tools/models/tool_request.dart';
import 'package:pharos_ai_runtime/tools/models/tool_status.dart';
import 'package:pharos_ai_runtime/tools/runtime/tool_validator.dart';
import 'package:test/test.dart';

Tool _tool({ToolStatus status = ToolStatus.available}) => Tool(
  id: const ToolId('web-search'),
  name: 'Web Search',
  description: '',
  status: status,
  capabilities: {const ToolCapability('web-search')},
  supportedOperations: const ['search'],
  metadata: const {},
);

ToolRequest _request({
  Set<ToolCapability>? requestedCapabilities,
  String operation = 'search',
  Duration timeout = const Duration(seconds: 5),
}) => ToolRequest(
  taskId: 'task-1',
  requestedCapabilities:
      requestedCapabilities ?? {const ToolCapability('web-search')},
  operation: operation,
  parameters: const {},
  timeout: timeout,
  metadata: const {},
);

void main() {
  const validator = ToolValidator();

  test('valid request against a matching, available tool has no errors', () {
    expect(validator.validate(_tool(), _request()), isEmpty);
  });

  test('missing tool produces "Tool does not exist."', () {
    expect(validator.validate(null, _request()), ['Tool does not exist.']);
  });

  test('unsupported capability is reported', () {
    final errors = validator.validate(
      _tool(),
      _request(requestedCapabilities: {const ToolCapability('git-commit')}),
    );

    expect(errors, isNotEmpty);
    expect(errors.first, contains('git-commit'));
  });

  test('unsupported operation is reported', () {
    final errors = validator.validate(
      _tool(),
      _request(operation: 'delete-everything'),
    );

    expect(errors, isNotEmpty);
    expect(errors.first, contains('delete-everything'));
  });

  test('disabled tool is reported', () {
    final errors = validator.validate(
      _tool(status: ToolStatus.disabled),
      _request(),
    );

    expect(errors, contains('Tool "web-search" is disabled.'));
  });

  test('non-positive timeout is reported', () {
    final errors = validator.validate(
      _tool(),
      _request(timeout: Duration.zero),
    );

    expect(errors, contains('Request timeout must be greater than zero.'));
  });

  test('multiple violations are all reported together', () {
    final errors = validator.validate(
      _tool(status: ToolStatus.disabled),
      _request(operation: 'delete-everything', timeout: Duration.zero),
    );

    expect(errors, hasLength(3));
  });

  test('is deterministic for the same inputs', () {
    expect(
      validator.validate(_tool(), _request()),
      validator.validate(_tool(), _request()),
    );
  });
}
