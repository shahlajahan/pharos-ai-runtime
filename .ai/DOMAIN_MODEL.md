# Pharos Domain Model

This document defines the core concepts of the Pharos Platform.

It describes responsibilities and relationships only.

No implementation details.

No APIs.

No code.

---

# Runtime

The Runtime is the execution kernel of Pharos.

It is responsible for executing AI employees safely and consistently.

The Runtime owns execution.

It does not own business logic.

---

# Employee

An Employee is an autonomous worker.

Employees perform business tasks.

Examples:

- Marketing Employee
- Sales Employee
- Support Employee
- Research Employee

Employees define goals.

They do not define execution infrastructure.

Employees use:

- Workflow
- Memory
- Tools

Employees never communicate with infrastructure directly.

---

# Workflow

A Workflow defines how an Employee performs work.

A workflow is a sequence of execution steps.

A workflow contains no business knowledge.

It only defines execution order.

Examples:

Marketing Workflow

↓

Research

↓

Planning

↓

Writing

↓

Review

↓

Publish

---

# Execution Step

A Step is one executable unit inside a workflow.

A Step has only one responsibility.

Examples:

- call a Tool
- read Memory
- write Memory
- ask an LLM
- evaluate a condition

Steps should remain small.

---

# Tool

A Tool allows interaction with external systems.

Examples:

- HTTP
- GitHub
- Firestore
- Files
- Email
- Slack

Tools perform actions.

They do not contain business logic.

---

# Memory

Memory stores information.

Memory is responsible only for persistence.

Examples:

- Conversation Memory
- Vector Memory
- Local Memory
- Firestore Memory

Memory does not execute workflows.

Memory does not make decisions.

---

# Job

A Job represents one execution instance.

Every Runtime execution creates exactly one Job.

Jobs are immutable.

---

# Context

Contexts transport execution data.

Examples:

ExecutionContext

ToolContext

MemoryContext

Contexts never contain business logic.

---

# Result

Every executable operation returns a Result.

Result communicates:

- success

or

- failure

No exceptions should escape subsystem boundaries.

---

# Registry

Registries resolve implementations.

Examples:

ToolRegistry

MemoryRegistry

Registries never execute work.

They only resolve objects.

---

# Invoker

Invokers execute resolved implementations.

Examples:

ToolInvoker

MemoryInvoker

Invokers contain execution boundaries.

Invokers return Results.

---

# Platform

The Pharos Platform consists of multiple reusable subsystems.

```

Runtime

↓

Employees

↓

Workflow

↓

Memory

↓

Tooling

```

Products are built on top of the Platform.

Examples:

- Petsupo
- DevAudit
- DevClean

The Platform contains no product-specific logic.

---

# Architectural Rules

Business logic belongs to Employees.

Execution belongs to Runtime.

Execution order belongs to Workflow.

External communication belongs to Tools.

Persistence belongs to Memory.

Products orchestrate Employees.

Subsystems communicate through contracts.

No subsystem owns another subsystem.

Dependencies always point downward.

---

# Long-term Vision

Traditional software executes functions.

Pharos executes employees.

The Runtime should eventually support hundreds of independent AI employees running on the same execution platform.

This document intentionally describes concepts, not implementations.

Implementations may evolve.

The domain model should remain stable.