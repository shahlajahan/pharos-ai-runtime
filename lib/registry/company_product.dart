/// One product in the Pharos company's own product portfolio.
class CompanyProduct {
  const CompanyProduct({
    required this.name,
    required this.enabled,
    required this.description,
    required this.targetAudience,
    required this.valueProposition,
  });

  final String name;
  final bool enabled;
  final String description;
  final String targetAudience;
  final String valueProposition;
}
