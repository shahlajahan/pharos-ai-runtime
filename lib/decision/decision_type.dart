/// The fixed set of decision categories the Decision Engine can
/// produce. New categories can be added here without changing
/// DecisionEngine's ranking or rendering logic.
enum DecisionType {
  launch,
  improve,
  connect,
  fix,
  review,
  monitor,
  document,
  research,
  blocker,
  risk,
}
