/// One Execution's (or ExecutionStep's) lifecycle state. Shared between
/// [Execution] and `ExecutionStep` since both progress through the same
/// vocabulary; `planned` doubles as a step's "not started yet" state.
enum ExecutionStatus { planned, running, paused, completed, failed, cancelled }
