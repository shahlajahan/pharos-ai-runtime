/// A project owned by a Company. Immutable domain model only — no
/// services, no calculations.
class Project {
  const Project({required this.id, required this.name});

  final String id;
  final String name;
}
