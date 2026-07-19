/// A product owned by a Company. Immutable domain model only — no
/// services, no calculations.
class Product {
  const Product({required this.id, required this.name});

  final String id;
  final String name;
}
