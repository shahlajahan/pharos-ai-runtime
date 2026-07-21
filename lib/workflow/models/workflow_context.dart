/// Everything required before a Workflow may execute: Company Context,
/// Market Context, and Financial Context — no workflow should execute
/// without all three. Immutable, structural data only: no AI, no API
/// calls, no service references. Concrete Company/Market/Financial
/// context providers are future roadmap work (Phase 3 — Company
/// Context); this model only defines the shape every Workflow depends
/// on.
class WorkflowContext {
  const WorkflowContext({
    required this.company,
    required this.market,
    required this.finance,
  });

  final Map<String, Object> company;
  final Map<String, Object> market;
  final Map<String, Object> finance;
}
