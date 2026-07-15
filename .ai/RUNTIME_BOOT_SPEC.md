# Runtime Boot Specification

Goal

Boot a Pharos HQ before executing any agent.

Boot Sequence

CLI
 ↓
Runtime
 ↓
LocalHQSource
 ↓
HQBootstrap
 ↓
AgentRegistry
 ↓
Agent.run()

Failure Rules

- Invalid HQ → stop immediately
- Missing HQ → stop immediately
- Unknown agent → stop immediately

Success Rules

- HQ booted
- Agent resolved
- Agent executed

Out of Scope

- Employee parsing
- Memory loading
- Knowledge loading
- Workflow execution