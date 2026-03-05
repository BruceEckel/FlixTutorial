# A Gentle Introduction to Effect Systems

If you have programmed in almost any language, you have written functions that do more than just
compute a value. They print to the screen. They read files. They update a database. They roll dice.
These "extra things" a function does beyond returning a value are called **side effects**.

Most languages treat side effects as invisible. You call a function, and you have to read its body —
or its documentation, if you are lucky — to find out what it might do to the world around it.

An **effect system** makes side effects visible in the type of a function. The compiler reads and
enforces them, so you never have to wonder. This chapter explains what that means, why it matters,
and how Flix puts it into practice.

---

## 1. What Is a Side Effect?

Consider a very simple function:

```flix
def add(x: Int32, y: Int32): Int32 = x + y
```

This function takes two integers and returns their sum. That is all it does. Nothing else in the
program changes when you call it. It does not write to a file, it does not contact a server, it
does not modify any variable outside itself. It is **completely self-contained**.

Now consider this function:

```flix
def greetAndAdd(x: Int32, y: Int32): Int32 \ IO =
    println("Adding ${x} and ${y}");
    x + y
```

This function does the same arithmetic, but it also **prints a message** to the screen. That
printing is a side effect: it reaches outside the function and changes something in the world
(the contents of the terminal). The `\ IO` in the signature is how Flix marks that fact — but
we will get to that shortly.

---

## 2. Common Side Effects

Side effects come in many forms. Here are the ones you will encounter most often:

| Side Effect | Example |
|---|---|
| **I/O** | Printing to the screen, reading from the keyboard |
| **File system** | Reading or writing files |
| **Network** | Fetching a URL, sending a message |
| **Randomness** | Rolling a dice, generating a UUID |
| **Exceptions** | Throwing an error that unwinds the call stack |
| **Mutable state** | Modifying a global variable or a shared data structure |

All of these are "extra things" a function can do beyond returning its result.

---

## 3. The Problem with Invisible Effects

In most languages, the type signature of a function tells you only what goes **in** and what
comes **out**. It says nothing about what the function might do to the world.

Here is a Go-style example (not real Flix):

```
func processOrder(order Order) Result
```

Does `processOrder` write to a database? Send an email? Log to a file? Throw an exception?
**You cannot tell from the signature.** You have to read the implementation — or hope the
documentation is complete and accurate.

This has real consequences:

- **Testing is hard.** A function with hidden effects is difficult to test in isolation. You need
  to set up (and tear down) all the external systems it might touch.
- **Reasoning is hard.** When a bug appears, you cannot tell which functions might have caused
  it without reading every body.
- **Order matters in surprising ways.** Two calls that look independent might actually interfere
  because they both modify the same shared state.
- **Refactoring is risky.** Moving a function call can silently change program behaviour if it
  has effects you did not notice.

---

## 4. Pure Functions: The Gold Standard

A function with **no side effects** is called **pure**. Pure functions have a remarkable property:

> **Given the same inputs, a pure function always returns the same output — and does nothing else.**

This makes them extremely easy to reason about. You can think of a pure function the same way
you think of a mathematical function: `add(3, 4)` is always `7`, no matter when or how many times
you call it. Call it once, call it a million times, the result is the same and nothing else happens.

Because pure functions are predictable:

- **Testing is trivial.** Just call the function with inputs and check the output. No setup needed.
- **You can cache results.** If the function is always the same for the same input, you can store
  the answer and skip recalculation.
- **You can run them in parallel.** Two pure functions can never interfere with each other.
- **You can reorder calls freely.** There are no hidden dependencies to worry about.

The challenge is: in most languages, you have no way to *guarantee* a function is pure. You can
name it `computePure` and document it as pure, but nothing stops a colleague (or future you) from
accidentally adding a `println` inside it.

---

## 5. Making Effects Visible: The Core Idea

An effect system solves this by **recording effects in the type** of a function. Instead of effects
being a hidden implementation detail, they become part of the function's contract — something the
compiler reads, checks, and enforces.

Here is how Flix expresses it:

```flix
// Pure: no effect annotation means no effects.
def add(x: Int32, y: Int32): Int32 = x + y

// Impure: \ IO declares that this function performs I/O.
def greet(name: String): Unit \ IO =
    println("Hello ${name}!")
```

The `\ IO` after the return type is the **effect annotation**. It is not a comment. It is part of
the type. Here is how to read the full signature:

```
def greet  (name: String)  :  Unit   \  IO
    ──┬──   ──────┬──────     ──┬──  ─  ─┬─
      │           │             │         └─ effect: performs I/O
      │           │             └─ return type: returns nothing useful
      │           └─ parameter
      └─ function name
```

The compiler reads the effect annotation and enforces it. If you try to call `println` inside a
function that lacks `\ IO`, **the compiler rejects it**:

```flix
// This does not compile!
def silentGreet(name: String): Unit =
    println("Hello ${name}!")   // Error: println requires IO effect
```

This is the fundamental guarantee: **if a function has no effect annotation, the compiler has
verified that it performs no side effects.** Purity is not a convention or a hope — it is a
proven fact.

---

## 6. The Effect Set

Flix represents effects as a **set**. A function can have zero, one, or many effects:

```flix
// No effects (pure)
def inc(x: Int32): Int32 = x + 1

// One effect
def logValue(x: Int32): Unit \ IO =
    println("Value: ${x}")

// Multiple effects
def fetchAndLog(url: String): String \ {IO, Net} =
    let response = Http.get(url);
    println("Got response");
    response
```

The curly braces `{ }` denote a set of effects. You can think of the effect set as a
**list of permissions**: this function is allowed to do I/O, allowed to use the network,
and nothing else.

An empty effect set `\ { }` means the function is pure. Flix lets you write this explicitly,
though it is more common to just omit the annotation:

```flix
def inc(x: Int32): Int32 \ { } = x + 1   // explicitly pure
def inc(x: Int32): Int32 = x + 1          // same thing, preferred
```

---

## 7. Effects Are Contagious (In a Good Way)

Here is something important: **if you call an impure function, your function becomes impure too**.

Consider a chain of calls:

```
main()              -- calls sendReport, so: \ IO
  └─ sendReport()   -- calls logToFile, so: \ IO
       ├─ formatReport()   -- pure, no effects
       └─ logToFile()      -- writes a file: \ IO
```

`main` performs I/O because it calls `sendReport`, which calls `logToFile`, which writes to a file.
The I/O effect **propagates upward** through the call chain. Every function that (directly or
indirectly) performs I/O must declare `\ IO`.

This is not a burden — it is the feature. By looking at any function's signature, you can
**immediately know** whether it or anything it calls touches the outside world:

```flix
def processData(data: List[Int32]): List[Int32]          // purely transforms data
def processAndSave(data: List[Int32]): Unit \ IO         // also writes somewhere
```

No need to read the bodies. The signatures tell the whole story.

---

## 8. Effect Polymorphism: Effects That Depend on Inputs

Consider `List.map`. It applies a function to every element of a list:

```flix
List.map(x -> x + 1, List#{1, 2, 3})              // pure: just adds 1 to each element
List.map(x -> { println(x); x }, myList)           // impure: prints each element
```

Should `List.map` itself be pure or impure? **It depends on the function you pass to it.**

Flix handles this with **effect polymorphism**. The signature of `List.map` uses an *effect
variable* `ef` that gets filled in based on the argument:

```flix
def map(f: a -> b \ ef, l: List[a]): List[b] \ ef
```

Read this as: "`map` has whatever effect `f` has." The effect variable `ef` is filled in
automatically at each call site:

| Function passed to `map` | Effect of `f` | Effect of `map` |
|---|---|---|
| `x -> x + 1` | `{ }` (pure) | `{ }` (pure) |
| `x -> { println(x); x }` | `IO` | `IO` |

This means you get **one implementation of `List.map`** that works correctly for both pure and
impure functions. The effect system automatically tracks the right answer. You do not need a
pure version and an impure version of every library function — one suffices.

---

## 9. User-Defined Effects

So far, we have talked about `IO` — a built-in effect. But Flix lets you define **your own
effects**. This is one of its most powerful features, and it goes by several names: *algebraic
effects*, *user-defined effects*, or simply *effects and handlers*.

The key insight is a separation of concerns:

> **Define *what* an effect is separately from *how* it is handled.**

Let us look at a concrete example. Suppose you are writing a program that needs to ask the user
a question. Instead of calling `stdin` directly, you define an effect:

```flix
eff Ask {
    def ask(prompt: String): String
}
```

This says: "`Ask` is an effect. A function using it can call `Ask.ask(prompt)`, which yields a
`String`." Notice there is **no implementation here** — just the declaration that this capability
exists.

Now a function can *use* the effect without knowing how it will be handled:

```flix
def greetUser(): Unit \ {Ask, IO} =
    let name = Ask.ask("What is your name?");
    println("Hello, ${name}!")
```

`greetUser` declares that it uses the `Ask` effect (and `IO` for printing). But it does not know
whether `Ask.ask` will read from the terminal, return a hardcoded value for testing, or read from
a config file. **That decision is made elsewhere, by a handler.**

---

## 10. Handlers: Giving Effects Their Meaning

A **handler** provides the implementation for an effect. You attach it at the call site using
`run { ... } with handler`:

```flix
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

Here, the handler for `Ask` says: "When `ask` is called, print the prompt, read a line from the
terminal, and hand that line back to the program."

The `resume` argument is the **continuation** — it represents the rest of the program that was
waiting for the answer. Here is the sequence of what happens at runtime:

1. `greetUser` calls `Ask.ask("What is your name?")`
2. The handler intercepts the call
3. The handler prints `"What is your name?"`
4. The handler reads the user's input — say, `"Alice"`
5. The handler calls `resume("Alice")`, handing the answer back
6. `greetUser` continues with `name = "Alice"`
7. `greetUser` calls `println("Hello, Alice!")`

The handler eliminates the effect. After the `run { } with handler Ask { }` block, the `Ask`
effect is gone — handled and resolved. `main` is left with only `\ IO` (from the `println`
calls), not `\ {Ask, IO}`.

---

## 11. Why Separate Effects from Handlers?

This separation — declaring an effect separately from handling it — gives you something
remarkable: **the same program logic can behave differently depending on which handler you attach**.

```flix
// In production: reads from the terminal
run { greetUser() } with handler Ask {
    def ask(prompt, resume) =
        println(prompt); resume(readLine())
}

// In tests: always returns "Alice", no terminal needed
run { greetUser() } with handler Ask {
    def ask(_prompt, resume) = resume("Alice")
}

// Reading from a config file instead
run { greetUser() } with handler Ask {
    def ask(_prompt, resume) = resume(Config.get("username"))
}
```

The function `greetUser` is written once and never changes. You swap the *handler* to change the
behaviour. This is **dependency injection**, but enforced by the type system — and without any
framework, interface, or annotation beyond the effect declaration itself.

---

## 12. Non-Resumable Effects: Exceptions

Not every effect needs to resume. Sometimes an effect should **abort** the computation entirely —
like an exception.

Flix represents this with a `Void` return type on the effect operation:

```flix
eff DivByZero {
    def divByZero(): Void   // Void means: cannot resume
}

def divide(x: Int32, y: Int32): Int32 \ DivByZero =
    if (y == 0) DivByZero.divByZero()
    else x / y
```

`Void` is a type with no values — so there is literally nothing for the handler to pass to
`resume`, and the computation cannot continue from that point. The handler instead decides what
to do next:

```flix
def main(): Unit \ IO =
    run {
        println(divide(10, 2));   // prints 5
        println(divide(10, 0))    // raises DivByZero — second println never runs
    } with handler DivByZero {
        def divByZero(_resume) =
            println("Error: division by zero")
    }
```

When `divide(10, 0)` raises `DivByZero`, the handler intercepts it and prints the error message.
The `_resume` argument exists in the handler signature but cannot be called — the underscore
prefix signals that it is intentionally ignored. Execution does not return to the `run` block;
the handler is the end of the road for that computation.

This is equivalent to a checked exception — but composable, first-class, and tracked in the type
system without any special `throws` declaration or try/catch syntax baked into the language.

---

## 13. Putting It All Together

| Concept | In one sentence |
|---|---|
| **Side effect** | Anything a function does beyond returning a value |
| **Pure function** | A function with no side effects |
| **Effect annotation** | `\ IO` — declares effects as part of the function type |
| **Effect polymorphism** | Higher-order functions inherit the effects of their arguments |
| **User-defined effect** | `eff Name { def op(): ReturnType }` — declare a new capability |
| **Handler** | `run { } with handler Name { }` — give an effect its implementation |
| **Non-resumable effect** | An effect with `Void` return — like a typed, composable exception |

---

## 14. Why This Matters

Effect systems answer a question that most languages leave open:

> **"What does this function do to the world?"**

In Flix, the answer is always in the type signature. The compiler enforces it. You do not need
to read the body, trust the documentation, or learn from a production incident.

This makes large codebases easier to navigate. It makes testing straightforward — pure functions
need no mocking or test doubles. It makes refactoring safer — the compiler tells you when you
accidentally add an effect. And it makes it possible to write reusable logic (like `greetUser`)
that is independent of *how* its effects are handled.

Effect systems are not magic. They do require you to think about what your functions do and to
say so in their types. But that discipline pays off quickly: code that was previously a guess
becomes code you can reason about with confidence.

---

*Next: [The Effect System in Flix](FlixCheatSheet.md#7-the-effect-system) — a detailed look at
all three layers: pure/impure, effect polymorphism, and algebraic effects with handlers.*
