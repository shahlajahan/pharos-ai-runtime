import 'package:pharos_ai_runtime/workflow/models/workflow_priority.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_step_status.dart';
import 'package:pharos_ai_runtime/workflow/models/workflow_type.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowType', () {
    test('has exactly the roadmap-defined values, in order', () {
      expect(WorkflowType.values.map((type) => type.name).toList(), [
        'launchCampaign',
        'partnerOutreach',
        'productRelease',
        'customerSupport',
        'engineeringTask',
        'financeReview',
        'operations',
        'custom',
      ]);
    });

    test('round-trips through its name for serialization', () {
      for (final type in WorkflowType.values) {
        expect(WorkflowType.values.byName(type.name), type);
      }
    });
  });

  group('WorkflowPriority', () {
    test('has exactly critical, high, medium, low, in that order', () {
      expect(WorkflowPriority.values, [
        WorkflowPriority.critical,
        WorkflowPriority.high,
        WorkflowPriority.medium,
        WorkflowPriority.low,
      ]);
    });

    test('round-trips through its name for serialization', () {
      for (final priority in WorkflowPriority.values) {
        expect(WorkflowPriority.values.byName(priority.name), priority);
      }
    });
  });

  group('WorkflowStatus', () {
    test('has exactly the roadmap-defined values, with no "draft"', () {
      expect(WorkflowStatus.values.map((status) => status.name).toList(), [
        'planned',
        'ready',
        'running',
        'paused',
        'completed',
        'failed',
        'cancelled',
      ]);
      expect(
        WorkflowStatus.values.map((status) => status.name),
        isNot(contains('draft')),
      );
    });

    test('round-trips through its name for serialization', () {
      for (final status in WorkflowStatus.values) {
        expect(WorkflowStatus.values.byName(status.name), status);
      }
    });
  });

  group('WorkflowStepStatus', () {
    test('has exactly the roadmap-defined values, in order', () {
      expect(WorkflowStepStatus.values.map((status) => status.name).toList(), [
        'pending',
        'ready',
        'running',
        'completed',
        'failed',
        'skipped',
      ]);
    });

    test('round-trips through its name for serialization', () {
      for (final status in WorkflowStepStatus.values) {
        expect(WorkflowStepStatus.values.byName(status.name), status);
      }
    });
  });
}
