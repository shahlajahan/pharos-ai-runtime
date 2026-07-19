/// What the Company wants to achieve, independent of how it will be
/// executed. Intent answers "why are we doing something?" — it is not
/// Work, not Workflow, not Execution. Pure identity — no methods, no
/// behavior.
abstract interface class Intent {
  String get id;

  String get title;
}
