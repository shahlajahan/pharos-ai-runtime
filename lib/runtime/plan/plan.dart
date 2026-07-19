/// Runtime's own Plan abstraction — the first concrete artifact Planning
/// produces. Pure identity — no behavior.
abstract interface class Plan {
  String get id;

  String get title;
}
