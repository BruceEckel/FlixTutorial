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
`Unit -> a`, where `a` is whatever type the value turns out to be.

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
```

But this has a hidden cost. When you call it like this:

```flix
debugLog(false, "Result: ${expensiveComputation()}")
```

Flix is eager. Before `debugLog` is even called, it evaluates all the arguments — including
`expensiveComputation()`. The expensive work runs even though the message will never be printed.

A thunk fixes this cleanly. Instead of passing a ready-made `String`, you pass a function that
*produces* a `String`:

```flix
def debugLog(enabled: Bool, makeMessage: Unit -> String \ IO): Unit \ IO =
    if (enabled) println(makeMessage()) else ()

// The expensive formatting only runs if enabled is true
debugLog(false, () -> "Result: ${expensiveComputation()}")
```

Now when `enabled` is `false`, `makeMessage` is never called. The sealed envelope stays sealed.
The expensive computation never runs.

### Two things to know about thunks

First, thunks are not a Flix invention. This pattern works in every language that has
first-class functions — JavaScript, Python, Scala, Haskell, all of them. It is a general
technique, and you will recognise it once you start looking.

Second, there is a downside worth knowing: **if you call the thunk twice, it runs twice**. There
is no built-in memory of the previous result. If `expensiveComputation()` takes a second to run
and you call the thunk ten times, you wait ten seconds. This is called the absence of
*memoization* — and Flix's `lazy` keyword, coming in the next section, is the answer to it.

### A note on effects

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
## 4. Lazy Data Structures: `DelayList`
## 5. The Reveal: Effect Handlers Were Delaying All Along
## 6. Controlling the Delay
## 7. Real Problems That Need Delay
## 8. Summary
