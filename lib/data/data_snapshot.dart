/// Shared runtime context populated by the Data Source Layer.
///
/// A DataSnapshot will eventually carry information from every company
/// system the runtime can connect to. It is only a shared container: it
/// holds no business logic, no validation, no computation — each
/// DataSource is responsible for populating its own section, and nothing
/// else reads or interprets that data here.
///
/// Sections start out empty and are populated in place as each
/// DataSource's [DataSource.refresh] call fills in whatever it knows.
class DataSnapshot {
  DataSnapshot({
    Map<String, dynamic>? crm,
    Map<String, dynamic>? social,
    Map<String, dynamic>? trends,
    Map<String, dynamic>? news,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? competitors,
  }) : crm = crm ?? {},
       social = social ?? {},
       trends = trends ?? {},
       news = news ?? {},
       analytics = analytics ?? {},
       competitors = competitors ?? {};

  final Map<String, dynamic> crm;
  final Map<String, dynamic> social;
  final Map<String, dynamic> trends;
  final Map<String, dynamic> news;
  final Map<String, dynamic> analytics;
  final Map<String, dynamic> competitors;
}
