/// Something a Company does. Departments do Work, Employees perform
/// Work, Agents execute Work — this is the shared identity contract
/// across all of them. Pure identity — no behavior, no scheduling, no
/// execution.
abstract interface class Work {
  String get id;

  String get title;
}
