import 'package:pharos_ai_runtime/workflow/simulation/workflow_simulation.dart';

/// The outcome of one WorkflowSimulator.simulate() call. [simulation]
/// stays null only when the workflow could not be simulated at all (for
/// example it has no steps) — [success] is otherwise true even when
/// [warnings] or [WorkflowSimulation.blockedSteps] are non-empty, since
/// reporting a blocked or incomplete preview is exactly the simulator's
/// job.
class SimulationResult {
  const SimulationResult({
    required this.success,
    required this.simulation,
    required this.errors,
    required this.warnings,
  });

  final bool success;
  final WorkflowSimulation? simulation;
  final List<String> errors;
  final List<String> warnings;
}
