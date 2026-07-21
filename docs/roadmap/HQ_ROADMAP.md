# Pharos AI Runtime Roadmap

Version: 1.0
Status: Active
Owner: Pharos Teknoloji
Last Updated: 2026-07-20

---

# Vision

Pharos AI Runtime is not another AI agent.

It is the execution engine of Pharos Teknoloji.

Its mission is to continuously understand the company, collect information from every internal and external source, reason about that information, and help every department make better decisions.

Eventually it will become the operating system of the company.

---

# Long-Term Goal

The Runtime should eventually know:

- every company product
- every employee
- every customer
- every partner
- every business asset
- every active marketing campaign
- every sales opportunity
- every financial metric
- every important industry trend
- every competitor movement

and transform that information into actions.

The Runtime should never rely on assumptions.

It should always reason over real company data.

---

# Core Philosophy

LLMs are not the source of truth.

They are reasoning engines.

Everything they generate must be based on verified company knowledge.

The Runtime never asks:

"Write me a marketing post."

Instead it asks:

"Given today's company state, today's trends, current KPIs, competitors, budget, CRM status and marketing strategy, what should we publish today?"

---

# Architecture Philosophy

                Human
                   │
                   ▼
            Pharos HQ
                   │
                   ▼
          Company Knowledge
                   │
                   ▼
        Internal Data Sources
                   │
                   ▼
        External Data Sources
                   │
                   ▼
          Unified Context
                   │
                   ▼
               LLM
                   │
                   ▼
         Business Decisions
                   │
                   ▼
             Automation

---

# Current Status

Completed:

✅ Runtime Core

✅ Workflow Engine

✅ Tool Registry

✅ OpenRouter Integration

✅ Real LLM Connection

✅ Data Source Layer

Current Phase:

➡ Building the Company Brain

---

# Development Phases

---

## Phase 1

Foundation

Status:
✅ Completed

Goal

Build the Runtime infrastructure.

Deliverables

- CLI
- Workflow Engine
- Tool Registry
- OpenRouter Integration
- Configuration
- Logging
- Basic Execution

Outcome

The Runtime can execute real workflows.

---

## Phase 2

Company Brain

Status:
🚧 In Progress

Goal

Transform Pharos HQ into the single source of truth.

This phase establishes the initial Company Brain. Documentation should be sufficient for the Runtime to discover company assets. It does not need to be exhaustive. The Company Brain evolves continuously alongside Runtime development.

No new connectors should be written until the Runtime knows what exists inside the company.

Deliverables

Complete documentation for:

- Products
- Services
- Platforms
- Accounts
- Websites
- Social Media
- Analytics
- CRM
- Infrastructure
- Domains
- Payment Providers
- AI Providers
- Company Knowledge

Outcome

The Runtime can discover every company asset without guessing.

---

## HQ-037

Complete Pharos HQ

Status:
Planned

Goal

Complete the HQ documentation until every important business asset can be discovered automatically.

Tasks

Complete every Product

Complete every Service

Complete every Platform

Complete every Website

Complete every Social Account

Complete every Analytics Property

Complete every Firebase Project

Complete every Repository

Complete every CRM

Complete every AI Service

Acceptance Criteria

The Runtime can answer:

"What assets belong to Petsupo?"

without hardcoded logic.

---

## Phase 3

Connectors

Goal

Connect the Runtime to real systems.

Examples

CRM

Firebase

GitHub

OpenAI

Google Analytics

Search Console

Meta

LinkedIn

X

Google Maps

Google Workspace

Calendar

Gmail

Cloud Storage

Finance Systems

Payment Providers

Outcome

The Runtime reads live company information.

---

## Phase 4

Intelligence Layer

Goal

Understand the business.

Examples

Competitor Intelligence

Market Intelligence

Trend Detection

News Monitoring

SEO Monitoring

Customer Intelligence

Revenue Intelligence

Marketing Intelligence

Outcome

The Runtime understands what is happening.

Not just what exists.

---

## Phase 5

Decision Layer

Goal

Turn knowledge into decisions.

Examples

Should we publish today?

Should we contact this lead?

Should we increase ad budget?

Should we stop a campaign?

Should we build this feature?

Should we hire?

Should we release?

Outcome

The Runtime produces business recommendations.

---

## Phase 6

Department Agents

Goal

Every department has an AI worker.

Marketing Agent

Sales Agent

Finance Agent

Engineering Agent

Operations Agent

Legal Agent

Customer Success Agent

Executive Agent

Outcome

Every department can ask intelligent questions.

---

## Phase 7

Automation

Goal

Execute approved actions.

Examples

Publish content

Reply to emails

Generate reports

Create invoices

Schedule meetings

Update CRM

Open GitHub Issues

Generate landing pages

Generate videos

Generate images

Launch campaigns

Outcome

The Runtime becomes an execution platform.

---

## Phase 8

Autonomous Company

Long-Term Vision

The Runtime continuously:

Collects information

Updates knowledge

Reasons

Plans

Executes

Measures

Learns

Improves

without requiring humans to manually assemble context.

Humans remain responsible for strategy.

The Runtime becomes responsible for execution.

---

# Development Rules

Rule 1

Never build connectors before the Runtime knows what it should connect to.

Rule 2

Never let an LLM guess company information.

Rule 3

Every task must produce a real executable result.

Rule 4

HQ is always the primary source of truth.

Rule 5

Live systems update HQ.

HQ updates Runtime.

Runtime updates business decisions.

---

# Success Criteria

The project succeeds when a CEO can ask:

"What should Pharos do today?"

and the Runtime can answer using:

- company knowledge
- live analytics
- CRM
- finance
- trends
- competitors
- ongoing projects
- marketing
- engineering
- operations

instead of generating generic AI responses.

---

# Final Goal

Build an AI Operating System for Pharos Teknoloji.

Not another chatbot.

Not another agent.

An operating system capable of understanding, reasoning, deciding and eventually executing across the entire company.