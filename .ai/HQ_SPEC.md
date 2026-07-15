# Pharos HQ Specification

Version: 0.1

Status: Draft

---

# Purpose

This document defines the minimum structure that a Pharos HQ repository
must expose so it can be executed by Pharos AI Runtime.

This is a structural specification only.

It does not define markdown formats,
employee schemas,
memory formats,
or workflow execution.

---

# Design Principles

The Runtime owns execution.

The HQ owns knowledge.

The Runtime never owns company data.

The HQ never owns execution logic.

---

# Minimum HQ

A valid HQ repository MUST contain:

```
employees/
knowledge/
```

Everything else is optional.

---

# Required Directories

## employees/

Contains employee definitions.

The Runtime discovers employees from here.

The Runtime does not modify this directory.

---

## knowledge/

Contains company knowledge.

The Runtime may read this directory.

The Runtime never writes into it.

---

# Optional Directories

The following directories may exist.

Their absence must never invalidate an HQ.

```
memory/
playbooks/
policies/
departments/
assets/
docs/
templates/
scripts/
workflows/
adr/
standards/
company/
```

---

# Unknown Directories

Unknown directories must be ignored.

Example:

```
photos/
archive/
legacy/
```

These must never invalidate an HQ.

---

# Runtime Responsibilities

The Runtime is responsible for:

- loading HQ
- validating HQ structure
- discovering employees
- executing employees

The Runtime is NOT responsible for:

- creating HQ
- modifying HQ
- migrating HQ

---

# HQ Responsibilities

The HQ is responsible for:

- company knowledge
- employee definitions
- policies
- playbooks
- documentation

The HQ never executes itself.

---

# Validation Rules

A valid HQ:

- exists
- contains required directories

Nothing more.

No markdown parsing.

No employee validation.

No workflow validation.

No memory validation.

---

# Future Extensions

Future versions may introduce:

- Git sources
- Remote sources
- Version metadata
- Plugin manifests

These extensions must not change the minimum HQ definition.

---

# Compatibility

Runtime implementations should remain compatible with this specification
whenever possible.

Breaking changes require a new specification version.