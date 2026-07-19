/// One step within an immutable Plan produced by a Planner.
class PlanStep {
  const PlanStep({required this.description, required this.assignedEmployee});

  final String description;

  /// The id of the Employee Workflow must execute this step with, via
  /// HQ.invoke(employee: assignedEmployee, ...).
  final String assignedEmployee;
}
