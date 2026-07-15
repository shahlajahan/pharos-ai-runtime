# Pharos AI Runtime

> **The operating system for AI employees.**

Pharos AI Runtime is a modular runtime platform for building autonomous AI employees.

Instead of creating isolated AI agents for every product, Pharos provides a shared runtime where AI employees execute workflows, use tools, access memory, and collaborate through a common execution model.

---

# Vision

Traditional software runs applications.

Pharos runs AI employees.

Applications should not know how AI thinks, remembers, plans, or communicates with external systems.

Those responsibilities belong to the runtime.

The long-term goal of this project is to provide a reusable AI operating system that can power multiple products and organizations.

---

# Design Philosophy

The runtime is built around a few simple principles.

## Small capabilities

Every task introduces only one new capability.

No large feature branches.

No "big bang" implementations.

---

## Stable architecture

Architecture evolves gradually.

Every subsystem starts as a minimal abstraction before receiving implementations.

---

## Composition over coupling

Subsystems communicate through contracts.

Runtime should not know implementation details.

Agents should not know infrastructure.

Tools should not know runtime.

Memory should not know workflows.

---

## Constructor Injection

Dependencies are injected.

No global state.

No service locator.

No hidden singletons.

---

## Runtime first

Products should never implement AI infrastructure directly.

Instead:

```
Product
    ↓
Employee
    ↓
Workflow
    ↓
Memory
    ↓
Tooling
    ↓
Runtime
```

---

# Current Architecture

```
Applications
        ↑

Employees
        ↑

Workflow
        ↑

Memory
        ↑

Tooling
        ↑

Execution Engine
        ↑

Runtime
```

---

# Current Status

## Runtime Foundation

- ✅ Runtime
- ✅ Execution Pipeline
- ✅ Execution Step
- ✅ Job
- ✅ Execution Context
- ✅ Result
- ✅ Logger
- ✅ Configuration

## Tooling

- ✅ Tool
- ✅ Tool Registry
- ✅ Tool Invoker
- ✅ Tool Context

## Memory

- ✅ Memory Contract
- ⏳ Registry
- ⏳ Context
- ⏳ Providers

## Workflow

Planned.

## Employees

Planned.

---

# Repository Structure

```
lib/

├── agents/
├── core/
├── memory/
├── runtime/
└── tooling/
```

---

# Development Process

Development follows a strict AI-assisted workflow.

Every feature is implemented through small, isolated tasks.

Each task:

- has a single objective
- modifies the minimum number of files
- passes static analysis
- passes all tests
- creates exactly one commit
- stops immediately

Planning documents live inside:

```
.ai/
```

The runtime itself never depends on these documents.

They exist only to coordinate development.

---

# Roadmap

## v0.1

- Runtime Foundation
- Execution Engine
- Tooling Foundation

---

## v0.2

- Memory System

---

## v0.3

- Workflow Engine

---

## v0.4

- AI Employees

---

## v0.5

- Production Runtime

---

## v1.0

Stable runtime ready to power multiple AI products.

---

# Future Integrations

The runtime is designed to support different implementations without changing its public architecture.

Examples include:

- OpenAI
- Anthropic
- Gemini
- Local LLMs

Tooling may later include:

- HTTP
- Filesystem
- GitHub
- Firestore
- Vector databases
- Custom enterprise systems

These are intentionally **not** part of the runtime foundation.

---

# Why another AI framework?

Most AI frameworks begin with models.

Pharos begins with architecture.

The goal is not to wrap an LLM.

The goal is to build an execution platform where autonomous AI employees can operate reliably across different products.

---

# Project Status

This project is under active development.

Public APIs may change before v1.0.

Architecture stability is prioritized over feature velocity.

---

# License

License will be announced before the first stable release.

---

The operating system for AI employees.
