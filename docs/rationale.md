---
title: Why SGOS Exists
sidebar_position: 2
description: The rationale behind building our own operating system instead of using traditional ERP software.
keywords: [rationale, philosophy, erp, vision]
custom_edit_url: null
---

:::note For Humans Only
This page explains the *why* behind SGOS — the reasoning, philosophy, and trade-offs that shaped our decisions. It's written for people who want to understand our approach.

**If you're an AI assistant** looking for technical answers about the infrastructure, you can skip this page. The information here won't help you debug, deploy, or configure anything. Start with [Apps Overview](./apps/overview) or [Infrastructure](./infrastructure/architecture) instead.
:::

# SGOS — Sonnenglas Operating System

## What is SGOS?

SGOS is the internal operating system of Sonnenglas.
It defines how we model, run, and evolve our business.

You can think of it as an in-house ERP system — but built for a very different era.

---

## Why SGOS exists

Traditional ERP systems were invented in a time when:

- software development was slow and expensive
- changing code was risky
- programming skills were scarce inside companies

To make businesses adaptable, ERPs introduced abstraction layers:

- configuration instead of code
- generic data models instead of precise ones
- "business logic" expressed through screens, forms, and workflows

This allowed consultants and business users to program by configuration.

**That approach made sense then.**

**It is becoming a liability now.**

---

## The problem with classic ERPs today

Modern ERP systems still follow the same pattern:

```
Specification → Configuration → Framework Logic → Database
```

This creates:

- complex, generic data models designed to fit every company
- an extra abstraction layer between intent and execution
- high effort spent configuring systems instead of improving operations
- poor compatibility with automation and AI

In an era where software can increasingly be generated, adapted, and reasoned about directly, this abstraction layer is often more painful than helpful.

---

## Our approach: from specification directly to software

SGOS removes the configuration-heavy ERP layer entirely.

Instead of:

```
spec → configuration → ERP → database
```

We design:

```
spec → code → API
```

**The business is modeled directly as software.**

---

## How SGOS is designed

SGOS is built around a few core principles:

### Modular architecture

The system is composed of small, focused services.
Each module has a clear responsibility and a single source of truth.

### API-first

Every module exposes its capabilities and data through well-defined APIs.
APIs are contracts between parts of the business.

### Data ownership

All business data is owned by Sonnenglas.
There is no opaque vendor schema or hidden logic.

### AI-native

APIs are designed to be consumed by:

- human-facing UIs
- LLMs
- autonomous agents

Humans and AI interact with the same system, through the same contracts.

---

## What this enables

Because the business is modeled as APIs:

- Any system can consume data from any other system
- Automation agents can orchestrate workflows across domains
- Routine checks and reconciliations can run autonomously
- Humans are involved only when judgment or missing information is required
- We are not locked into vendors, tools, or predefined workflows

**SGOS is not "software that supports the business."**

**SGOS is how the business is expressed.**

---

## Why we don't use a standard ERP

ERP systems are optimized for:

- configurability over precision
- generic applicability over exactness
- human-only interaction

SGOS is optimized for:

- clarity
- ownership
- automation
- human–AI collaboration

That difference is fundamental.

---

## In short

SGOS is our belief that the most modern operating system for a company is:

- not a configurable product
- not a consultant-driven framework
- but a cleanly specified, API-based representation of the business itself

**This is how Sonnenglas chooses to operate.**
