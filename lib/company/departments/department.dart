/// A functional area within a Company. Pure identity — no behavior, no
/// runtime logic. What a Department does is out of scope for this
/// foundational domain model.
abstract interface class Department {
  String get id;

  String get name;
}
