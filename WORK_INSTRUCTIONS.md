# WORK_INSTRUCTIONS.md

# Purpose

This repository is developed using ChatGPT Work as a long-term development assistant.

The objective is to maintain a scalable architecture while minimizing unnecessary project analysis. Work efficiently, but never sacrifice correctness for efficiency.

---

# Project Context

Before implementing any feature, understand the current development stage.

Current priorities are documented in:

1. README.md
2. EnemyArchitecture.md
3. ITEM_ARCHITECTURE.md

These documents should only be read when their content is relevant to the current task.

Do not automatically read every document before every implementation.

These documents are the primary source of truth.

If a documented decision conflicts with implementation, explain the conflict before proposing changes.

Assume that previously accepted architectural decisions are intentional.

Do not re-evaluate previously accepted architecture unless the current task directly depends on it or the user explicitly requests a review.

Avoid restarting architectural discussions that have already been settled.

---

# Context Strategy

Documentation always has priority over source code.

Only inspect source files when documentation is insufficient.

Never scan the entire repository unless the user explicitly requests a full architectural review.

Read only the files directly related to the current task.

Load additional files incrementally as needed.

Avoid repeatedly inspecting files already analyzed during the current conversation unless they have changed.

When additional source code is required, explain which file is needed and why before reading more project files.

---

# Architecture Rules

Respect every architecture document marked as frozen.

Do not redesign systems because a different solution seems cleaner.

Architecture should only change when implementation demonstrates a real limitation.

Prefer extending existing systems instead of introducing new ones.

Avoid speculative abstractions.

Prefer composition over deep inheritance.

---

# Implementation Rules

Keep the project playable after every task.

Work in small, verifiable slices.

Reuse existing systems whenever possible.

Avoid creating generic managers or runtime systems unless they solve an existing problem.

When multiple solutions are valid, choose the one that integrates naturally with the current architecture.

Do not modify unrelated systems while implementing a feature.

---

# Communication

Do not summarize the entire project before answering.

Focus only on the systems relevant to the current task.

Avoid repeating information already established during the conversation.

When documentation already answers the question, answer directly without inspecting additional source files.

If implementation details are required, inspect only the files directly involved.

---

# Documentation

If an implementation changes an architectural decision, update the corresponding architecture document.

Do not duplicate documentation across multiple files.

Each document should have a single responsibility.

When documentation and implementation disagree, report the inconsistency instead of silently assuming one is correct.

---

# Development Philosophy

Gameplay drives architecture.

Prefer incremental evolution over large refactors.

Do not optimize for hypothetical future mechanics.

Validate ideas through implementation and playtesting before expanding the architecture.

Long-term maintainability is more important than short-term convenience.

Correctness has priority over minimizing context, but unnecessary project exploration should always be avoided.