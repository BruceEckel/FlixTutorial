# A Gentle Introduction to Delayed Execution in Flix

In the previous chapter we met side effects and effect handlers — Flix's way of describing and controlling what a function is allowed to do. Now we go deeper into a related idea: sometimes you don't want computation to happen immediately at all. Flix offers three distinct mechanisms for delaying execution, each more powerful than the last, and understanding how they relate to one another unlocks a clearer mental model of the whole language. This chapter is purely orientation; code examples come in the sections that follow.

## 1. What Does "Delay" Mean?

Think about a recipe. When you read a recipe, no cooking happens. The instructions sit on the
page, patient and inert. The meal only comes into existence when someone decides to follow those
instructions — when they actually cook.

Most code works the opposite way: it is **eager**. The moment the interpreter reaches an
expression, it evaluates it. This line:

```flix
let x = 2 + 3
```

runs the addition immediately. By the time `x` exists, the computation is finished and the result
`5` is already stored.

Eagerness is usually exactly what you want. But sometimes you want to describe a computation
without running it yet — to hand the recipe to someone else, to run it later, or to run it only
if certain conditions are met.

That gap between *describing* a computation and *running* it is what we mean by **delay**.

Flix offers three mechanisms for this, each more powerful than the last. The simplest is a plain
function that takes no arguments. The next adds a built-in `lazy` keyword with its own evaluation
guarantee. The most powerful — algebraic effect handlers — turns out to have been delaying
computation all along, in a way the previous chapter only hinted at. This chapter walks through
all three.

---

## 2. Thunks: The Simplest Delay

A **thunk** is a function that takes no arguments and returns a value. In Flix, its type is
`Unit -> a`, where `a` is a type variable standing for any return type.

Think of it like a sealed envelope. You write instructions inside and seal it up — nothing
happens yet. The instructions sit there, patient. Only when someone opens the envelope (calls
the function) do those instructions actually run.

Here is the pattern, shown side by side:

```flix
// Eager: the addition happens right now
let x: Int32 = 2 + 3   // x is already 5

// Thunk: the addition is wrapped up, not yet run
let t: Unit -> Int32 = () -> 2 + 3   // nothing computed yet
let y: Int32 = t()                    // now it runs
```

The only difference is the `() ->` wrapper. Without it, Flix evaluates the expression
immediately and stores the result. With it, Flix stores a small function object — the sealed
envelope — and nothing is computed until you call it with `t()`.

### A motivating example: conditional logging

Suppose you have a debug logger. You want it to print messages only when debugging is turned on.
The naive approach looks fine at first:

```flix
def debugLog(enabled: Bool, message: String): Unit \ IO =
    if (enabled) println(message) else ()

debugLog(false, "Result: ${List.range(0, 1_000_000) |> List.length |> ToString.toString}") // pretend this is slow
```

But this has a hidden cost. Flix is eager. Before `debugLog` is even called, it evaluates all
the arguments — including the expensive string formatting. The expensive work runs even though
the message will never be printed.

A thunk fixes this cleanly. Instead of passing a ready-made `String`, you pass a function that
*produces* a `String`:

```flix
def debugLog(enabled: Bool, makeMessage: Unit -> String \ IO): Unit \ IO =
    if (enabled) println(makeMessage()) else ()

// The expensive formatting only runs if enabled is true
debugLog(false, () -> "Result: ${List.range(0, 1_000_000) |> List.length |> ToString.toString}") // pretend this is slow
```

Now when `enabled` is `false`, `makeMessage` is never called. The sealed envelope stays sealed.
The expensive computation never runs.

### Two things to know about thunks

First, thunks are not a Flix invention. This pattern works in every language that has
first-class functions — JavaScript, Python, Scala, and Haskell. It is a general
technique, and you will recognise it once you start looking.

Second, there is a downside worth knowing: **if you call the thunk twice, it runs twice**. There
is no built-in memory of the previous result. If the thunk takes a second to run and you call it
ten times, you wait ten seconds. Thunks do not cache results — they have no *memoization*. Flix's
`lazy` keyword, coming in the next section, is the answer to it.

### Thunks with effects

If a thunk performs I/O — say, it calls `println` or reads user input — the effect annotation
goes on the function type itself:

```flix
let t: Unit -> String \ IO = () -> { println("computing..."); "done" }
```

The `\ IO` is part of the type `Unit -> String \ IO`. It is not inside the body; it is part of
the function's signature. This follows the same rule as any other function in Flix: effects are
declared in the type, not hidden in the implementation.

---

## 3. `lazy` and `force`: Built-In Lazy Evaluation

Thunks are wonderfully simple, but they have the limitation we saw at the end of Section 2: every
time you call a thunk, it runs the computation from scratch. Call it three times, and you do the
work three times. There is no memory of the previous answer.

Flix's built-in `Lazy[T]` type solves this. Like a thunk, it defers an expression so it does not
run immediately. Unlike a thunk, it remembers the result the first time it is computed — and every
subsequent access returns that remembered value without re-running anything. This property is
called **memoization**.

### Basic syntax

The two keywords are `lazy` and `force`:

```flix
let x: Lazy[Int32] = lazy (1 + 2)   // not evaluated yet
let result: Int32 = force x          // evaluates now, result is 3
let again: Int32 = force x           // returns 3 immediately — no recalculation
```

`lazy (expr)` wraps the expression in a `Lazy[T]` container without evaluating it. The
parentheses are required. `force x` unwraps the container: if the expression has not run yet,
it runs now; if it has already run, the cached value is returned directly.

### Three properties, one at a time

**Delayed.** The expression inside `lazy (...)` does not run when you write it. It runs only
when you call `force` on it. Until that moment, the container sits there like an unopened box —
the instructions are stored, but no computation has taken place.

**Memoized.** Once forced, the result is cached inside the container. Force it ten times and
the expression runs exactly once. All ten `force` calls after the first simply read back the
stored value. This is the key advantage over a thunk.

**Pure only.** The expression inside `lazy` must have no side effects. The Flix compiler enforces
this — it is not just a convention. If you try to put a `println` inside a `lazy`, the compiler
rejects it:

```flix
// This does NOT compile — intentionally wrong to show the error
let bad: Lazy[Unit] = lazy (println("hi"))
// Error: expected pure expression, but expression has effect: IO
```

The reason this restriction exists follows directly from memoization. If the expression could
have side effects, the number of times those effects occur would depend on whether the value
had been forced before — a subtle and hard-to-predict behaviour. By requiring purity, Flix
makes the guarantee clean: the expression runs at most once, and nothing else in the world
changes as a side effect of that evaluation.

### When memoization matters: an example

Imagine you have an expensive value — something that takes real work to compute — and you need
to refer to it in several different places. With a thunk, every reference re-runs the work:

```flix
// Thunk: runs the full computation each time
let sumThunk: Unit -> Int32 \ {} = () -> List.range(0, 1_000_000) |> List.sum

let a = sumThunk()   // runs List.range and List.sum — full work
let b = sumThunk()   // runs it again — full work again
let c = sumThunk()   // and again
```

With `Lazy[T]`, the computation happens at most once:

```flix
// Lazy: runs once, remembered forever
let sumLazy: Lazy[Int32] = lazy (List.range(0, 1_000_000) |> List.sum)

let a = force sumLazy   // runs List.range and List.sum — once
let b = force sumLazy   // returns cached result immediately
let c = force sumLazy   // same cached result, no work done
```

`a`, `b`, and `c` all receive the same value, but the expensive work only happens the first
time `force` is called. This is exactly the situation `Lazy[T]` is designed for: a pure,
costly computation that is needed in multiple places.

### Thunk vs. `Lazy[T]` at a glance

| Feature                | Thunk `() -> a`      | `Lazy[T]`        |
|------------------------|----------------------|------------------|
| Evaluate later?        | Yes                  | Yes              |
| Evaluates once?        | No (runs each call)  | Yes (memoized)   |
| Can have effects?      | Yes                  | No (pure only)   |

The choice between them comes down to what you need. If you want to delay an effectful
computation — one that prints, reads input, or modifies state — a thunk is your tool. If you
want to delay a pure computation and share its result across multiple consumers without
recomputing it, `Lazy[T]` is exactly right.

---

## 4. Lazy Data Structures: `DelayList`

`Lazy[T]` delays a single value. That is already useful, but the real power of laziness emerges
when you build it into a data structure. Once a list node can hold a lazy tail, something
remarkable becomes possible: a list that never ends.

### The key insight

A normal list node holds a head value and an already-computed tail. To represent ten thousand
elements, you must have ten thousand nodes sitting in memory right now.

A lazy list node holds a head value and a *not-yet-computed* tail. The tail is wrapped in a
`Lazy`, so it does not exist until you ask for it. To represent ten thousand elements you only
need as many nodes as you have actually requested — because the rest have not been computed yet.

Push this idea to its limit and you get a list that is *conceptually infinite*: there is always
a next element, but it is only materialised at the moment you reach for it.

### How `DelayList` is built (conceptual)

Flix's standard library provides a `DelayList` type. Here is the shape of the idea — this is
**illustrative only**, not code to compile:

```
// How DelayList works internally (conceptual)
enum DelayList[a] {
    case DNil
    case DCons(a, Lazy[DelayList[a]])
}
```

`DNil` is the empty list — the end. `DCons` holds a head element of type `a` and a lazy tail
that is itself another `DelayList[a]`. Because the tail is wrapped in `Lazy`, it is not computed
until something forces it. Each node knows how to produce the *next* node, but does not produce
it until asked.

### Using `DelayList` in practice

The API provides the familiar higher-order functions — `map`, `filter`, `take` — but they all
operate lazily. Here is a complete example:

```flix
def main(): Unit \ IO =
    let naturals = DelayList.from(1);           // 1, 2, 3, 4, ... (never ends)
    let evens    = DelayList.map(x -> x * 2, naturals);
    let first10  = DelayList.take(10, evens);
    println(first10)
```

### What actually happens, step by step

- `DelayList.from(1)` does **not** generate an infinite list. It creates one node: head = `1`,
  tail = `lazy (from(2))`. The tail expression is wrapped, not evaluated. The list beyond the
  first element does not yet exist.

- `DelayList.map(x -> x * 2, naturals)` creates a new lazy list that knows how to double each
  element. Still nothing is computed. The doubling function has not been applied to any number.

- `DelayList.take(10, evens)` is where evaluation actually begins. It forces the first node,
  gets the head, forces the next node to get its head, and so on — ten times. At no point are
  more than ten elements evaluated.

- The final result `first10` is already an ordinary `List[Int32]` — `take` returns a plain list, not a lazy one. `println` prints it directly.

### The lazy chain

Here is what the structure looks like in memory as `take` does its work:

```
DCons(1, lazy ──► DCons(2, lazy ──► DCons(3, lazy ──► ...)))
                  ↑                  ↑
              not yet computed    not yet computed
```

Each node points to the next, but the arrow is a deferred computation — not an actual node —
until `take` forces it. The `...` at the end is not a placeholder for stored data; it is the
*recipe* for the next node, waiting to be invoked.

### Filtering a lazy list

`DelayList.filter` works the same way. You can ask for only the odd numbers:

```flix
let odds = DelayList.filter(x -> x mod 2 != 0, DelayList.from(1));
println(DelayList.take(5, odds))
// Output: 1 :: 3 :: 5 :: 7 :: 9 :: Nil
```

The filter predicate is applied element by element, on demand. Elements that fail the test are
skipped without ever materialising in a result structure. You can filter an infinite list and
only pay for the elements you actually consume.

This is the promise of lazy data structures in one sentence: **you describe a potentially
unbounded computation, and the runtime computes exactly as much of it as you ask for — no
more.**

---

## 5. The Reveal: Effect Handlers Were Delaying All Along

We have now seen two mechanisms for delaying execution. A thunk wraps an expression in a
`() -> a` function — nothing runs until you call it. `Lazy[T]` does the same for pure
expressions, adding memoization so the work happens at most once. Both are about taking a single
expression and postponing it.

There is a third mechanism. You have already used it — in the previous chapter. And it turns out
it was delaying execution all along, in a way that is worth making fully explicit.

### Recalling the `Ask` handler

Here is the core example from the previous chapter, reproduced so you do not need to flip back:

```flix
eff Ask {
    def ask(prompt: String): String
}

def greetUser(): Unit \ {Ask, IO} =
    let name = Ask.ask("What is your name?");
    println("Hello, ${name}!")

def main(): Unit \ IO =
    run {
        greetUser()
    } with handler Ask {
        def ask(prompt, resume) =
            println(prompt);
            let answer = readLine();
            resume(answer)
    }
```

Read this carefully. `greetUser` calls `Ask.ask(...)` and then, on the very next line, uses the
result to call `println`. There are two lines of code after the call site. They do not run
immediately. They wait.

### The execution flow

```
1. greetUser() calls Ask.ask("What is your name?")
2. Execution PAUSES — the rest of greetUser() is suspended
3. The handler runs: prints the prompt, reads a line
4. The handler calls resume("Alice")
5. greetUser() RESUMES with name = "Alice"
6. println("Hello, Alice!") runs
```

Step 2 is the key. When `Ask.ask(...)` fires, `greetUser` does not finish. It stops. The lines
below that call — `let name = ...` completing, then `println("Hello, ${name}!")` — are packaged
up and handed to the handler. They sit there, waiting, until the handler decides what to do with
them.

### The insight

> `resume` is a thunk. When `Ask.ask(...)` fires, the rest of `greetUser()` — every line after
> that call — is packaged up as a `Unit -> a` function and handed to the handler as `resume`.
> The handler holds the rest of the program. It can call `resume` whenever it wants.

This is the same pattern as Section 2 — a sealed envelope containing instructions — but the
envelope is not something you created by hand. Flix creates it automatically the moment an
effect operation fires. The handler receives it as the `resume` argument.

The rest of the program is the thunk. The handler is the one who decides whether to open it.

### Three mechanisms side by side

| Mechanism | What is delayed | Who holds the delay |
|---|---|---|
| Thunk `() -> a` | A single expression | You (the caller) |
| `Lazy[T]` | A single pure expression | The runtime |
| Effect handler | The rest of the program | The handler |

The first two columns grow in scale from top to bottom. A thunk delays one expression. `Lazy[T]`
delays one expression with a memory guarantee. An effect handler delays not one expression but
*everything that comes after the effect call* — the entire remaining computation, all the way
to the end of the `run` block.

### Why this is the most powerful form of delay

A thunk is a value. You hold it, you call it, and it produces a result. That is the full extent
of what you can do.

`resume` is also a value — a function — but what it represents is more profound. It is the
continuation of the program. Calling `resume("Alice")` does not just evaluate a small expression;
it picks up an entire suspended computation and runs it forward.

Because `resume` is just a function, the handler can do anything with it:

- **Call it once** — normal execution, the program continues as expected.
- **Never call it** — the computation is aborted. This is how non-resumable effects work, as in
  the `DivByZero` example from the previous chapter.
- **Call it multiple times** — the suspended computation runs multiple times, each time from the
  same point. This is how you get forking, backtracking, and non-determinism.

Thunks can only be called. `resume` can be called, ignored, stored, or duplicated. The
possibilities open up considerably. Section 6 explores what you can do when you take deliberate
control of this.

---

## 6. Controlling the Delay

The most common pattern: the handler does its work, then calls `resume` immediately.

```flix
eff Greet {
    def hello(name: String): Unit
}

def main(): Unit \ IO =
    run {
        Greet.hello("Alice");
        Greet.hello("Bob")
    } with handler Greet {
        def hello(name, resume) =
            println("Hello, ${name}!");
            resume()
    }
```

The handler prints the greeting, then immediately calls `resume()` to continue. The program runs
in a straight line. This is how most handlers work — they handle the effect, then hand control
back immediately. Nothing surprising happens: the two calls fire one after the other, the handler
runs for each, and the program ends.

But the handler is not required to call `resume` at all.

### Pattern 2 — Never call resume (abort)

```flix
eff Fail {
    def fail(msg: String): Void
}

def main(): Unit \ IO =
    run {
        println("Step 1");
        Fail.fail("something went wrong");
        println("Step 2")   // never runs
    } with handler Fail {
        def fail(msg, _resume) =
            println("Aborted: ${msg}")
    }
```

The `Void` return type on `def fail(msg: String): Void` is the signal. `Void` is a type with no
values — there is literally nothing to pass back to a continuation, so the computation cannot
resume from that point. The handler receives `_resume` in its argument list, but the leading
underscore marks it as intentionally unused.

When `Fail.fail(...)` fires, the rest of the `run` block is packaged up and handed to the handler
— just as always. But the handler simply prints the error message and returns. It never calls
`_resume`. The suspended computation, including `println("Step 2")`, is discarded.

This is a typed, composable exception. It has no special syntax — no `throw`, no `try`, no
`catch`. It is just an effect operation whose return type is `Void`, handled by a handler that
chooses not to resume.

### Pattern 3 — Call resume multiple times (fork/backtrack)

The handler can also call `resume` more than once. Each call picks up the same suspended
computation and runs it forward from the same point — but with a different value.

```flix
eff Flip {
    def flip(): Bool
}

def main(): Unit \ IO =
    run {
        let a = Flip.flip();
        let b = Flip.flip();
        println("${a}, ${b}")
    } with handler Flip {
        def flip(_, resume) =
            resume(true);
            resume(false)
    }
// Prints:
// true, true
// true, false
// false, true
// false, false
```

Tracing through this carefully is worth the effort.

When the first `Flip.flip()` fires, the handler is called. The suspended computation — everything
from `let a = ...` onward — is held in `resume`. The handler calls `resume(true)` first. This
runs the rest of the `run` block with `a = true`. That "rest of the block" includes a second
`Flip.flip()`, so the handler is invoked again. This time, calling `resume(true)` produces
`"true, true"` and calling `resume(false)` produces `"true, false"`.

Then control returns from the first `resume(true)` call and the handler continues to its next
line: `resume(false)`. This runs the rest of the block again, but now with `a = false`. The
second `Flip.flip()` fires again, and the handler produces `"false, true"` and `"false, false"`.

The result is all four combinations, in that order.

Calling `resume` multiple times does not loop in the conventional sense. It does not repeat a
block of code in a `for` or `while` loop. Instead, it literally runs the rest of the program
multiple times from the same point, each time with a different value threaded through. The handler
is not a loop body — it is a fork in the road.

This is how effect handlers can express search, backtracking, and non-determinism without any
special syntax beyond the effect and handler themselves.

### What the handler controls

The handler is the gatekeeper of the delay. It receives the suspended computation as `resume` and
decides three things: whether the suspended computation ever runs, how many times it runs, and
with what value it continues each time.

| Handler choice | Effect |
|---|---|
| Call `resume` once, immediately | Normal flow — the computation continues as written |
| Never call `resume` | Abort — the suspended computation is discarded |
| Call `resume` multiple times | Fork — the computation runs once for each call |

This single decision — what to do with `resume` — is how effect handlers express exception
handling, dependency injection, backtracking, and more. The pattern is always the same; only the
handler's choice changes.

---

## 7. Real Problems That Need Delay
## 8. Summary
