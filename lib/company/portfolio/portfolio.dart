import 'package:pharos_ai_runtime/company/products/product.dart';
import 'package:pharos_ai_runtime/company/projects/project.dart';

/// The part of a Company that owns its Products and Projects. Pure
/// domain structure only — no business logic, no calculations.
class Portfolio {
  const Portfolio({required this.products, required this.projects});

  final List<Product> products;
  final List<Project> projects;
}
