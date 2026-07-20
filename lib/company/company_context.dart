/// Structured company knowledge assembled from the HQ Workspace — the
/// only source of company facts an agent may reason from. Never raw
/// markdown: every entry is one normalized line per loaded document.
/// Sections a connector or category has not populated stay empty rather
/// than being invented.
class CompanyContext {
  const CompanyContext({
    required this.company,
    required this.knowledge,
    required this.products,
    required this.assets,
    required this.services,
    required this.websites,
    required this.social,
    required this.analytics,
  });

  final List<String> company;
  final List<String> knowledge;
  final List<String> products;
  final List<String> assets;
  final List<String> services;
  final List<String> websites;
  final List<String> social;
  final List<String> analytics;
}
