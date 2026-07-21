/// Exactly one capability an Agent may provide (for example
/// "image-generation", "copywriting", "flutter-development"). A plain
/// value object — not a permission, not a Tool, not a role.
///
/// Distinct from the unrelated `Capability` interface in
/// `lib/company/capabilities/capability.dart`, which describes what a
/// company *Department* is capable of doing (an organizational/
/// governance concept). The two coexist under different import paths;
/// this one is specifically an Agent's executable capability, used for
/// Task assignment matching.
class Capability {
  const Capability(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is Capability && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
