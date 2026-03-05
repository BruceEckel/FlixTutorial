# Design: A Gentle Introduction to Delayed Execution in Flix

**Date:** 2026-03-04
**Follows:** GentleEffectIntro.md
**Audience:** Novice/uninitiated programmers
**Output file:** GentleDelayedExecution.md

## Goal

A beginner-friendly chapter that explains how Flix handles delayed execution —
building from the simplest mechanism (thunks) through built-in lazy evaluation
(`Lazy[T]`), to the insight that effect handlers are a form of delayed execution
themselves. Ends with concrete real-world problems that motivate why delay matters.

## Approach

Option A (linear, simple → complex) with Option C (problem-first) at the end.
Matches the tone and pedagogical style of GentleEffectIntro.md: careful, unhurried,
concrete examples before abstract explanations.

## Chapter Structure

### Section 1 — What does "delay" mean?
Everyday intuition: knowing *what* to compute but not *when*. Eager evaluation
is the default. Sets up the motivation informally.

### Section 2 — Thunks: `Unit -> a`
Simplest delay: wrap computation in a zero-argument function. Create now, call
later. Universal pattern, but crude.

### Section 3 — `lazy` and `force`
Introduce `Lazy[T]`, the `lazy` keyword, `force`. Properties: evaluates once,
memoized, must be pure. Side-by-side eager vs. lazy examples.

### Section 4 — Lazy data structures: `DelayList`
`Lazy[T]` enables infinite structures. `DelayList.from` → `map` → `take`.
Intuition: a description of an infinite list; compute only what you request.

### Section 5 — The reveal: handlers were delaying execution all along
Connect to GentleEffectIntro.md. When an effect fires, the computation pauses.
`resume` is the paused computation. This is the same idea as sections 2–4,
at the level of whole-program control flow.

### Section 6 — Controlling the delay
Three handler patterns:
- Call `resume` immediately → normal flow
- Never call `resume` → abort (exception)
- Call `resume` multiple times → fork (backtracking, search)

### Section 7 — Real problems that need delay (Option C payoff)
1. Infinite sequences: filter/take from an endless stream
2. Retry logic: handler calls `resume` again on failure, business logic unchanged

### Section 8 — Summary table
Thunk vs. `Lazy[T]` vs. effect handler: when to use each.

## Style Constraints

- No jargon without definition
- Introduce one concept per section
- Every code example must be compilable Flix
- Use diagrams/ASCII art where helpful
- Match the voice of GentleEffectIntro.md
