/// The fixed set of fact kinds the Runtime understands today. New types
/// can be added here without changing FactExtractor's dispatch logic,
/// KnowledgeGraph, or DepartmentFactBuilder — every consumer only ever
/// switches on [FactType] to decide relevance, never assumes the full set.
enum FactType {
  company('Company'),
  capability('Capability'),
  product('Product'),
  service('Service'),
  website('Website'),
  domain('Domain'),
  brandAsset('Brand Asset'),
  mediaAsset('Media Asset'),
  socialAccount('Social Account'),
  analyticsPlatform('Analytics Platform'),
  repository('Repository'),
  infrastructure('Infrastructure'),
  competitor('Competitor'),
  targetMarket('Target Market'),
  technology('Technology'),
  subscription('Subscription'),
  paymentProvider('Payment Provider'),
  workflow('Workflow'),
  policy('Policy');

  const FactType(this.displayName);

  /// The human-readable name used in prompts and the printed report.
  final String displayName;
}
