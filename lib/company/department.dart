/// The fixed set of departments the Runtime reasons about today. New
/// departments can be added here without changing DepartmentContextBuilder,
/// DepartmentPromptBuilder, or the Runtime — every consumer iterates over
/// [Department.values].
enum Department {
  executive('Executive'),
  engineering('Engineering'),
  marketing('Marketing'),
  sales('Sales'),
  operations('Operations'),
  finance('Finance');

  const Department(this.displayName);

  /// The human-readable name used in prompts and the printed report.
  final String displayName;
}
