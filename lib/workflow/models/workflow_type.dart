/// The kind of business process a Workflow represents. Fixed set from
/// the roadmap; new kinds are added here without touching Workflow,
/// WorkflowStep, or WorkflowPlanner.
enum WorkflowType {
  launchCampaign,
  partnerOutreach,
  productRelease,
  customerSupport,
  engineeringTask,
  financeReview,
  operations,
  custom,
}
