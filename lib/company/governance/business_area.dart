/// A governance boundary within a Company — identifies which part of the
/// business an Ownership record refers to. Pure identity — no behavior,
/// no permissions.
abstract interface class BusinessArea {
  String get id;

  String get name;
}
