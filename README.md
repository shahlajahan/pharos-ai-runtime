# Pharos AI Runtime

> **The operating system for AI employees.**

> ⚠️ **Status:** Foundation Phase  
> Current milestone: **v0.2-memory-foundation**

Pharos AI Runtime is a modular execution platform for building autonomous AI employees.

Instead of embedding AI logic into every application, Pharos provides a reusable runtime responsible for execution, orchestration, tooling, memory, workflows, and eventually intelligent employees.

The goal is to separate **business intelligence** from **application code**.

---

# Vision

Traditional software executes functions.

Pharos executes AI employees.

Applications should never be responsible for how AI:

- plans
- remembers
- communicates
- executes
- collaborates

Those responsibilities belong to the runtime.

The long-term vision is to build a reusable AI operating system capable of powering many different products without rewriting AI infrastructure.

---

# Design Philosophy

The architecture follows a few simple principles.

## Small Capabilities

Every task introduces exactly one capability.

No large feature branches.

No "big bang" implementations.

Small steps produce stable architecture.

---

## Stable Contracts

Every subsystem begins as an abstraction.

Implementations come later.

Public contracts should remain stable.

---

## Composition over Coupling

Subsystems communicate through contracts.

Runtime should not know implementation details.

Employees should not know infrastructure.

Tools should not know Runtime.

Memory should not know Workflows.

---

## Constructor Injection

Dependencies are injected.

No global state.

No service locators.

No hidden singletons.

---

## One Responsibility per Class

Every class owns exactly one responsibility.

Responsibilities should never overlap.

---

## Runtime First

Products should never implement AI infrastructure directly.

Instead, every product builds on the same execution platform.

---

# Architecture

```
Applications
        │
        ▼
 Employees
        │
        ▼
 Workflows
        │
        ▼
 ┌──────────────────────┐
 │   Memory   |  Tools  │
 └──────────────────────┘
        │
        ▼
     Runtime
```

The Runtime owns execution.

Employees own business logic.

Workflows define execution order.

Tools communicate with external systems.

Memory stores information.

---

# Current Foundation

## Runtime

- ✅ Runtime
- ✅ Configuration
- ✅ Logger
- ✅ Result
- ✅ Job
- ✅ Execution Context
- ✅ Execution Pipeline
- ✅ Execution Step
- ✅ Exception Boundary

---

## Tooling

- ✅ Tool
- ✅ Tool Context
- ✅ Tool Registry
- ✅ Tool Invoker

---

## Memory

- ✅ Memory Contract
- ✅ Memory Context
- ✅ Memory Registry
- ✅ Memory Invoker

---

## Planned

- ⏳ Employees
- ⏳ Workflow Engine
- ⏳ Workflow Steps
- ⏳ Providers
- ⏳ LLM Integrations

---

# Repository Structure

```
lib/

core/
runtime/
tooling/
memory/
agents/
```

---

# Development Workflow

Development follows a strict AI-assisted workflow.

Every task:

- introduces one capability
- changes the minimum number of files
- passes static analysis
- passes all tests
- creates exactly one commit
- stops immediately

Planning documents live inside:

```
.ai/
```

They coordinate development only.

The runtime itself never depends on them.

---

# Roadmap

## v0.1

- Runtime Foundation
- Execution Engine
- Tooling Foundation

---

## v0.2

- Memory Foundation

---

## v0.3

- Employee Foundation

---

## v0.4

- Workflow Engine

---

## v0.5

- Provider System

---

## v0.6

- LLM Integrations

---

## v1.0

Stable runtime capable of powering multiple AI products.

---

# Why another AI framework?

Most AI frameworks begin with models.

Pharos begins with architecture.

The objective is not to wrap an LLM.

The objective is to create a reusable execution platform where autonomous AI employees can safely operate across different products.

---

# Current Status

🚧 Active Development

The architecture is intentionally stabilized before production features are introduced.

Public APIs may evolve until v1.0.

Architectural stability is prioritized over feature velocity.

---

# Planned Products

The same runtime is intended to power multiple products, including:

- Petsupo
- DevAudit
- DevClean

The runtime itself contains no product-specific logic.

---

# Contributing

The project is currently in its foundation phase.

Contributions are welcome after the core architecture reaches stability.

---

# License

The project is currently source-available during the foundation phase.

An open-source license will be announced before the first stable release (v1.0).
```