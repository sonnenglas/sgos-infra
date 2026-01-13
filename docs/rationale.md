---
title: Why SGOS Exists
sidebar_position: 2
description: The rationale behind building our own operating system instead of using traditional ERP software.
keywords: [rationale, philosophy, erp, vision]
custom_edit_url: null
---

:::note For Humans Only
This page explains the thinking behind SGOS. It's written for people, not machines. If you're an AI assistant looking for technical answers, skip to [Apps Overview](./apps/overview) or [Infrastructure](./infrastructure/architecture).
:::

# Why We Built Our Own System

SGOS is the internal operating system of Sonnenglas. It's how we run the company. You could call it an ERP, but that word carries baggage we'd rather leave behind.

## The ERP Bargain

Enterprise Resource Planning systems exist because of a bargain that made sense forty years ago.

Back then, writing software was expensive. Changing it was dangerous. Most companies had no programmers on staff, and hiring consultants to build custom systems cost a fortune. So the industry invented a different approach: instead of writing code, you'd configure a product. Instead of precise data models, you'd get generic ones designed to fit every business on earth. Instead of programming, you'd fill out forms and drag boxes around flowcharts.

This was clever. It let business people—not engineers—shape how their systems worked. Configuration replaced code. Consultants could implement systems without writing a line of software. Companies got flexibility without needing to understand computers.

The bargain was simple: accept abstraction in exchange for adaptability.

For decades, this worked well enough.

## The Abstraction Tax

But abstraction has a cost, and that cost compounds over time.

When you configure an ERP, you're not describing your business directly. You're describing it through a translation layer—someone else's idea of what businesses look like. Your inventory isn't *your* inventory; it's their inventory model with your data stuffed into it. Your orders aren't *your* orders; they're generic order objects with your fields mapped onto theirs.

This translation layer sits between what you want and what happens. Every question you ask has to pass through it. Every change you make has to respect it. Every automation you build has to work around it.

The more sophisticated your operations become, the more you feel this friction. You spend meetings discussing how to configure the system instead of how to improve the business. You hire specialists who understand the abstraction layer, not your actual domain. You accumulate workarounds and exceptions and "that's just how the system works" explanations.

The configuration layer that was supposed to give you freedom becomes a weight you drag behind you.

## The World Changed

Here's what's different now: software is no longer expensive to write.

Modern tools, frameworks, and languages have collapsed the cost of building things. A small team can create in weeks what used to take months. Code that once required specialists can now be written, understood, and modified by a much wider group of people.

And then there's AI.

Large language models can read APIs, understand data structures, and take actions. They can be given tools and taught to use them. They can orchestrate workflows, check for inconsistencies, and handle routine decisions. But they need something to work with—something legible, something structured, something designed for machine consumption.

ERPs weren't built for this. They were built for humans clicking through screens. Their interfaces are meant to be seen, not called. Their logic is buried in configuration, not exposed as contracts. Trying to automate an ERP is like trying to teach a robot to use a touchscreen: possible, but painful, and missing the point entirely.

## A Different Path

SGOS takes a different approach. We skipped the configuration layer.

Instead of: *specification → configuration → framework → database*

We build: *specification → code → API*

The business is modeled directly as software. Orders are orders, not generic transaction objects. Inventory is inventory, not a configured subset of a universal schema. When we need something to work differently, we change the code, not a settings page buried five menus deep.

This sounds harder. It's actually simpler.

Configuration creates the illusion of flexibility while hiding complexity in abstraction. Code is explicit. You can read it. You can trace it. You can understand exactly what happens when an order is placed or a payment is recorded. There's no magic layer interpreting your intent.

## How It Works

SGOS is a collection of small services, each responsible for one part of the business. Xhosa handles orders. Inventory tracks stock. Accounting manages money. Each service owns its data completely and exposes everything through APIs.

These APIs are contracts. They define what questions you can ask and what actions you can take. They're versioned, documented, and stable. When one service needs something from another, it calls an API. When a human needs to see something, a UI calls the same APIs. When an AI agent needs to check inventory or create a task, it calls the same APIs.

Everyone—humans, interfaces, and machines—interacts with the business through the same contracts.

This is what we mean by AI-native. It's not about chatbots or fancy demos. It's about building systems that are as legible to machines as they are to people. When your business logic is exposed as APIs, automation becomes straightforward. An agent can check stock levels, reconcile payments, flag anomalies, and escalate to humans when judgment is required—all through the same interfaces your team uses.

## What We Gain

Because we own the code, we own our future. There's no vendor deciding when to deprecate features we depend on. No consultants needed to explain why the system can't do something obvious. No generic data model forcing us to think in someone else's categories.

Because everything is APIs, automation is natural. Agents can orchestrate multi-step workflows across the entire business. Routine checks run continuously. Humans get involved when they're actually needed, not because the system can't proceed without a click.

Because the services are small and focused, change is safe. Modifying how orders work doesn't risk breaking accounting. Each piece can evolve independently, tested and deployed on its own schedule.

Because the data is ours—truly ours, in schemas we designed—we can query it, analyze it, and reshape it however we need. No export limitations. No proprietary formats. No begging for access to our own information.

## Why Not Just Buy Something?

We could have bought an ERP. Plenty of good ones exist. Some are even open source.

But every ERP comes with the same fundamental assumption: that configuration is better than code. That abstraction is worth the cost. That businesses should adapt to software rather than the other way around.

We don't believe that anymore.

## We've Been Here Before

This might sound like naivety—a small company thinking it can build what the industry has spent decades refining. We understand that skepticism because we've lived the cautionary tale ourselves.

Sonnenglas ran on custom software for years. It didn't work out. The systems became brittle. Changes took too long. Knowledge left with the people who built things. By 2023, we were actively planning to adopt a traditional ERP. We'd made our peace with the abstraction tax.

Then the ground shifted.

Large language models went from curiosity to capability. Suddenly, software that would have taken months could be built in days. Code that required specialists could be written, reviewed, and modified with a fundamentally different economics. The calculus that had pushed us toward ERPs—custom software is expensive, risky, and hard to maintain—stopped being true.

Two years ago, we would never have built SGOS. A small company couldn't afford that kind of investment. But the developments in software through AI have changed what's possible. Building isn't the constraint it used to be. Maintaining isn't the burden it used to be. The question isn't whether you can afford to build—it's whether you can afford not to.

## Looking Forward

The gap between what modern software can do and what traditional ERPs offer is growing every year. The abstraction tax gets heavier as expectations rise. The companies that thrive in the next decade won't be the ones with the most sophisticated configurations—they'll be the ones whose systems are genuinely programmable, genuinely automatable, genuinely theirs.

SGOS is a bet that the best operating system for a company isn't a product you configure. It's software you own, APIs you control, and contracts that work for humans and machines alike.

This is how we've chosen to run Sonnenglas.
