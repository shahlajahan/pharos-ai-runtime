/// A stable business concept describing what a Department is capable of
/// doing. Not a permission, not Work, not a role — pure identity only.
abstract interface class Capability {
  String get id;

  String get name;
}
