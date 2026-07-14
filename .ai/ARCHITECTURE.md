# Architecture

Runtime is only an orchestrator.

Runtime responsibilities:

- Load configuration
- Create execution context
- Resolve agent
- Execute agent
- Collect result
- Exit

Agents:

- Contain business logic
- Never call external services directly

All external communication must go through future services/tools.

No global state.

Dependency Injection preferred.

One responsibility per class.