/// One document loaded from the HQ Workspace, tagged with the category
/// (folder) it came from — for example `company`, `products`, or
/// `social`.
class CompanyDocument {
  const CompanyDocument({
    required this.category,
    required this.name,
    required this.content,
  });

  final String category;
  final String name;
  final String content;
}
