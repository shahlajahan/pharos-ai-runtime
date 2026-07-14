class Job {
  const Job({
    required this.id,
    required this.agentId,
    required this.createdAt,
  });

  final String id;
  final String agentId;
  final DateTime createdAt;
}
