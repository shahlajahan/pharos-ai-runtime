/// One document loaded from the HQ Workspace, tagged with the category
/// (folder) it came from — for example `company`, `products`, or
/// `social`.
class CompanyDocument {
  const CompanyDocument({
    required this.category,
    required this.name,
    required this.content,
    String? path,
  }) : path = path ?? name;

  final String category;
  final String name;
  final String content;

  /// The document's location relative to its category folder, including
  /// any subfolders, without the file extension (for example
  /// "websites/petsupo-com" for `assets/websites/petsupo-com.md`).
  /// Defaults to [name] when not given, which is already correct for a
  /// document with no subfolder.
  final String path;
}
