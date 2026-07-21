/// A Task's priority. Mirrors WorkflowPriority's fixed tiers, since a
/// Task inherits its urgency from the Workflow Step it was decomposed
/// from.
enum TaskPriority { critical, high, medium, low }
