# GentleDelayedExecution Chapter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Write `GentleDelayedExecution.md` — a beginner-friendly chapter on delayed execution in Flix, following GentleEffectIntro.md in style and audience.

**Architecture:** Linear progression (thunks → `Lazy[T]` → effect handlers as delay), closing with two real-world problem motivations. All code examples must be valid Flix syntax, verified against CLAUDE.md's syntax reference and the docs in `docs/doc.flix.dev/`. Sections are written one at a time, each committed independently so progress is reviewable.

**Tech Stack:** Flix (flix.jar), Markdown (GitHub-flavored CommonMark)

---

### Task 1: Scaffold the file with frontmatter and section headings

**Files:**
- Create: `GentleDelayedExecution.md`

**Step 1: Create the file with title, intro paragraph, and all H2 headings (no body yet)**

```markdown
# A Gentle Introduction to Delayed Execution in Flix

[intro paragraph]

## 1. What Does "Delay" Mean?
## 2. Thunks: The Simplest Delay
## 3. `lazy` and `force`: Built-In Lazy Evaluation
## 4. Lazy Data Structures: `DelayList`
## 5. The Reveal: Effect Handlers Were Delaying All Along
## 6. Controlling the Delay
## 7. Real Problems That Need Delay
## 8. Summary
```

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: scaffold GentleDelayedExecution.md with headings"
```

---

### Task 2: Write Section 1 — What Does "Delay" Mean?

**Files:**
- Modify: `GentleDelayedExecution.md`

**Step 1: Write the section body**

Everyday intuition: you know *what* to compute but not *when*. Examples:
- A restaurant menu describes meals that don't exist yet
- A recipe is instructions that run when you cook, not when you read
- `2 + 2` in code evaluates *immediately* — that's eager evaluation

Introduce "eager" as the default. Pose the question: what if you want to defer?

Key points to cover:
- Most code is eager: expressions evaluate the moment they are written
- Sometimes you want to describe a computation and run it later
- Flix has three ways to do this, each at a different level

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 1 - what does delay mean"
```

---

### Task 3: Write Section 2 — Thunks

**Files:**
- Modify: `GentleDelayedExecution.md`

**Step 1: Write the section body**

A thunk is a `Unit -> a` function. Show the pattern:

```flix
// Eager: evaluates now
let x = expensiveComputation();   // runs immediately

// Thunk: evaluates later
let delayed = () -> expensiveComputation();   // does nothing yet
let result = delayed();                       // runs now
```

Key points:
- Any function that takes `Unit` and returns a value is a thunk
- You create it now; you call it when you need the result
- Works in every language — this is not Flix-specific
- Downside: if you call it twice, it runs twice (no memoization)
- The `\ IO` effect (or other effects) must still be declared

Show a concrete motivating example: a function that logs an expensive message only if debugging is enabled.

**Step 2: Verify syntax** — thunks in Flix are just lambda functions `() -> expr`. Check CLAUDE.md syntax reference.

**Step 3: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 2 - thunks"
```

---

### Task 4: Write Section 3 — `lazy` and `force`

**Files:**
- Modify: `GentleDelayedExecution.md`
- Reference: `docs/doc.flix.dev/laziness.html`

**Step 1: Write the section body**

Introduce the problem with thunks: calling twice runs twice. Flix's solution: `Lazy[T]`.

```flix
// Create a lazy value (does not evaluate yet)
let x: Lazy[Int32] = lazy (1 + 2);

// Force evaluation (evaluates once, then caches)
let result: Int32 = force x;
```

Three properties to explain one at a time:
1. **Delayed**: the expression inside `lazy` does not run when you write `lazy (...)`. It runs when you `force` it.
2. **Memoized**: force it ten times — the expression runs exactly once. The result is cached.
3. **Pure only**: the expression inside `lazy` must have no effects. The compiler enforces this.

Show a side-by-side table:

| | Thunk `() -> a` | `Lazy[T]` |
|---|---|---|
| Evaluate later? | Yes | Yes |
| Evaluates once? | No (runs each call) | Yes (memoized) |
| Can have effects? | Yes | No (must be pure) |

Walk through a small motivating example: a lazy Fibonacci or a lazy expensive calculation.

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 3 - lazy and force"
```

---

### Task 5: Write Section 4 — Lazy Data Structures: `DelayList`

**Files:**
- Modify: `GentleDelayedExecution.md`
- Reference: `docs/doc.flix.dev/laziness.html`

**Step 1: Write the section body**

Build on `Lazy[T]` to explain why it enables infinite data structures.

Key insight: a `DelayList` node holds a head value and a *lazy* tail. The tail isn't computed until you ask for it. So you can have a list that is, in principle, infinite — because you only ever compute as much as you need.

Show `DelayList.from` to create an infinite list, then `map` and `take`:

```flix
def main(): Unit \ IO =
    let naturals = DelayList.from(1);           // 1, 2, 3, 4, ... forever
    let evens    = DelayList.map(x -> x * 2, naturals);
    let first10  = DelayList.take(10, evens);   // only computes 10 elements
    println(DelayList.toList(first10))
```

Explain why this works: `DelayList.from(1)` does not actually compute an infinite list. It computes the first element (`1`) and wraps the rest in a `lazy` thunk. The rest is computed only when `take` asks for it.

Use an ASCII diagram to show the lazy chain:

```
SCons(1, lazy SCons(2, lazy SCons(3, lazy ...)))
              ↑ not computed yet
```

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 4 - DelayList"
```

---

### Task 6: Write Section 5 — The Reveal

**Files:**
- Modify: `GentleDelayedExecution.md`

**Step 1: Write the section body**

This is the conceptual payoff of the linear build-up. Connect back to GentleEffectIntro.md.

Remind the reader what they already know: when `Ask.ask(prompt)` is called, the handler intercepts it. Show the sequence again:

```
greetUser() calls Ask.ask("What is your name?")
    ↓
Execution PAUSES here
    ↓
Handler runs
    ↓
Handler calls resume("Alice")
    ↓
greetUser() CONTINUES with name = "Alice"
```

Then name the insight explicitly:

> `resume` is a thunk — a suspended computation. The handler holds the rest of the program as a value it can call whenever it wants.

The three mechanisms are the same idea at different scales:

| Mechanism | What is delayed | Who holds the delay |
|---|---|---|
| Thunk `() -> a` | A single expression | You (the caller) |
| `Lazy[T]` | A single pure expression | The runtime |
| Effect handler | The rest of the program | The handler |

Key point: effect handlers are the most powerful form because they can delay, redirect, or replay entire computation trees — not just a single value.

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 5 - the reveal"
```

---

### Task 7: Write Section 6 — Controlling the Delay

**Files:**
- Modify: `GentleDelayedExecution.md`
- Reference: `docs/doc.flix.dev/effects-and-handlers.html`

**Step 1: Write the section body**

Three handler patterns, each shown with a small self-contained example.

**Pattern 1 — Call resume immediately (normal flow):**

```flix
eff Greet {
    def hello(name: String): Unit
}

run {
    Greet.hello("Alice");
    Greet.hello("Bob")
} with handler Greet {
    def hello(name, resume) =
        println("Hello, ${name}!");
        resume()   // continue immediately
}
```

**Pattern 2 — Never call resume (abort):**

```flix
eff Fail {
    def fail(msg: String): Void
}

run {
    println("Before");
    Fail.fail("something went wrong");
    println("After")   // never runs
} with handler Fail {
    def fail(msg, _resume) =
        println("Aborted: ${msg}")
    // _resume is intentionally not called
}
```

**Pattern 3 — Call resume multiple times (fork/backtrack):**

```flix
eff Flip {
    def flip(): Bool
}

run {
    let a = Flip.flip();
    let b = Flip.flip();
    println("${a}, ${b}")
} with handler Flip {
    def flip(_, resume) =
        resume(true);    // run the rest with true ...
        resume(false)    // ... then run it again with false
}
// Prints all four combinations: true,true  true,false  false,true  false,false
```

Explain: calling `resume` multiple times literally runs the rest of the program multiple times, once per call. This is how you get search, backtracking, and nondeterminism from a single mechanism.

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 6 - controlling the delay"
```

---

### Task 8: Write Section 7 — Real Problems That Need Delay

**Files:**
- Modify: `GentleDelayedExecution.md`

**Step 1: Write the section body**

Two worked problems that couldn't be solved without delay.

**Problem 1 — Infinite sequences**

Scenario: you want "all prime numbers less than 1000" but don't want to pre-generate a huge list.

```flix
def main(): Unit \ IO =
    let nats   = DelayList.from(2);
    let primes = DelayList.filter(isPrime, nats);
    let first5 = DelayList.take(5, primes);
    println(DelayList.toList(first5))   // [2, 3, 5, 7, 11]
```

Explain: `nats` is a description of all integers from 2 upward. `primes` is a description of the filtered stream. Nothing runs until `take(5, ...)` asks for exactly five elements. Without lazy evaluation, this would either crash (infinite loop) or require you to pick an upper bound upfront.

**Problem 2 — Retry logic via handlers**

Scenario: a network call that might fail; you want to retry up to 3 times without changing the business logic.

```flix
eff Fetch {
    def fetch(url: String): String
}

def reportWeather(): Unit \ {Fetch, IO} =
    let data = Fetch.fetch("https://example.com/weather");
    println("Weather: ${data}")

def withRetry(attempts: Int32): b \ (ef - Fetch) + IO =
    run {
        reportWeather()
    } with handler Fetch {
        def fetch(url, resume) =
            // simplified: in real code, check for actual failure
            if (attempts > 0)
                resume(Fetch.fetch(url))   // try again with one fewer attempt
            else
                println("All retries exhausted")
    }
```

Key point: `reportWeather` never changes. You swap in a different handler to get retry behaviour. The business logic is completely decoupled from the retry policy.

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 7 - real problems that need delay"
```

---

### Task 9: Write Section 8 — Summary Table

**Files:**
- Modify: `GentleDelayedExecution.md`

**Step 1: Write the closing summary**

Final comparison table:

| Mechanism | Syntax | Evaluates once? | Can have effects? | Power level |
|---|---|---|---|---|
| Thunk | `() -> expr` | No | Yes | Low |
| `Lazy[T]` | `lazy expr` / `force x` | Yes | No (pure only) | Medium |
| Effect handler | `run { } with handler` | Configurable | Yes | High |

Closing paragraph tying it all together: delay is a spectrum. Thunks are simple and universal. `Lazy[T]` adds memoization and safety for pure values. Effect handlers are the full-power version — they can pause, redirect, replay, and reshape entire computations. Flix gives you all three, and the type system tells you which is in use.

Add a "Next" link pointing onward (matching GentleEffectIntro.md's footer style).

**Step 2: Commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: add section 8 - summary and closing"
```

---

### Task 10: Verify all code examples compile

**Files:**
- Read: `GentleDelayedExecution.md`
- Reference: `CLAUDE.md` syntax reference

**Step 1: Read each code block and cross-check against CLAUDE.md syntax rules**

Check for:
- `def main(): Unit \ IO` (correct main signature)
- `lazy` / `force` used only on pure expressions
- Effect handlers use correct `run { } with handler Name { def op(arg, resume) = ... }` syntax
- `Void` return on non-resumable effects
- No wildcard imports
- `DelayList.*` functions exist in Flix stdlib

**Step 2: Note any corrections needed and fix them**

**Step 3: Final commit if any fixes were made**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: fix code examples in GentleDelayedExecution.md"
```

---

### Task 11: Final polish — rendering and cross-links

**Files:**
- Modify: `GentleDelayedExecution.md`

**Step 1: Verify GitHub Markdown rendering**

Check:
- All tables render correctly (header row, separator row, data rows)
- Code blocks all have `flix` language tag
- ASCII diagrams use code blocks to preserve spacing
- No raw HTML needed
- Section numbering is consistent

**Step 2: Add "Next" footer link matching GentleEffectIntro.md style**

GentleEffectIntro.md ends with:
```markdown
*Next: [The Effect System in Flix](FlixCheatSheet.md#7-the-effect-system) — ...*
```

Add a similar footer at the end of GentleDelayedExecution.md.

**Step 3: Final commit**

```bash
git add GentleDelayedExecution.md
git commit -m "docs: final polish on GentleDelayedExecution.md"
```
