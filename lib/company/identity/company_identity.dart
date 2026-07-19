/// A Company's stable identity. Pure domain model only — no validation,
/// no formatting, no id generation.
class CompanyIdentity {
  const CompanyIdentity({
    required this.id,
    required this.displayName,
    required this.legalName,
  });

  /// The stable identifier used internally.
  final String id;

  /// The public/company name.
  final String displayName;

  /// The registered legal entity name.
  final String legalName;
}
