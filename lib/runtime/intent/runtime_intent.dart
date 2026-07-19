/// Runtime's own Intent abstraction — the boundary through which an
/// intention crosses from the Company domain into Runtime, without
/// Runtime ever knowing what a CompanyIntent is. Pure identity — no
/// methods, no behavior.
abstract interface class RuntimeIntent {
  String get id;

  String get title;
}
