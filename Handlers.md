# Flix Effect Handlers: A Comprehensive Guide

## Introduction: The Problem with Side Effects

Every useful program interacts with the world: reading files, printing output, generating random numbers, making network requests. These interactions are called *side effects*, and they create several problems:

1. **Hidden dependencies**: A function that reads a config file has an implicit dependency on the file system, but its signature doesn't reveal this.

2. **Testing difficulty**: How do you test a function that sends emails? You don't want to actually send emails during tests.

3. **Inflexibility**: Code that directly calls `println` can only print to the console. What if you want to capture output for logging, or redirect it?

4. **Reasoning challenges**: When functions can do anything, it's hard to know what they'll actually do.

### Traditional Solutions and Their Tradeoffs

**Exceptions** handle error cases but only propagate upward. They're non-resumable—once thrown, you can't continue from where you left off.

**Dependency injection** passes services as parameters, but leads to parameter bloat and boilerplate.

**Monads** (as in Haskell) provide type-safe effect tracking but require awkward transformers when combining multiple effects, and the order of monad stacking matters.

### Algebraic Effects: A Better Way

Algebraic effects, pioneered in languages like Eff and Koka, offer an elegant solution:

- **Effects are declared** in function signatures, making dependencies explicit
- **Handlers are separate** from effect definitions, allowing different implementations
- **Handlers can resume** execution, enabling powerful control flow
- **Multiple effects compose** without monad transformer headaches
- **The compiler verifies** all effects are handled

Flix brings algebraic effects to the JVM, combining them with a practical, production-ready language.

## Core Concepts

### What is an Effect?

An effect is a declared capability—something a function might do. It's like an interface with no implementation:

```flix
eff Logger {
    def log(message: String): Unit
}
```

This declares that `Logger` is an effect with one operation: `log`. Functions can require this effect:

```flix
def processData(data: String): Unit \ Logger = {
    Logger.log("Starting processing");
    // ... do work ...
    Logger.log("Done")
}
```

The `\ Logger` annotation means "this function performs the Logger effect." The function calls `Logger.log()` but doesn't define what logging actually does.

### What is a Handler?

A handler provides the implementation for an effect:

```flix
run {
    processData("hello")
} with handler Logger {
    def log(message, resume) = {
        println("[LOG] ${message}");
        resume()
    }
}
```

The handler says: "When `Logger.log` is called, print the message with a prefix, then continue execution." The `resume()` call is crucial—it returns control to where the effect was invoked.

Note: `resume` is just a conventional name, not a reserved word. You could call it `k`, `cont`, `next`, or anything else—it's simply a parameter that holds the continuation function. The name `resume` is used because calling it "resumes" execution where the effect was invoked.

### Separation of Concerns

This separation is powerful. The same `processData` function can be used with different handlers:

```flix
// Handler that prints to console
run { processData(data) } with handler Logger {
    def log(msg, resume) = { println(msg); resume() }
}

// Handler that collects logs in a list (for testing)
run { processData(data) } with handler Logger {
    def log(msg, resume) = { appendToList(msg); resume() }
}

// Handler that discards logs (for performance)
run { processData(data) } with handler Logger {
    def log(_, resume) = resume()
}
```

## Tutorial: Building Up Handler Knowledge

### Step 1: A Minimal Effect

Let's start with the simplest possible effect:

```flix
eff Greet {
    def sayHello(): Unit
}

def greetUser(): Unit \ Greet = {
    Greet.sayHello()
}

def main(): Unit \ IO =
    run {
        greetUser()
    } with handler Greet {
        def sayHello(_, resume) = {
            println("Hello, World!");
            resume()
        }
    }
```

Key observations:
- `eff Greet` declares an effect with one operation
- `greetUser` uses the effect (note `\ Greet` in its signature)
- `main` handles the effect with `run { ... } with handler Greet { ... }`
- The handler's `def sayHello(_, resume)` has two parameters:
  - `_` for the operation's arguments (none here, so ignored)
  - `resume` is the continuation—calling it returns to where `sayHello()` was invoked

### Step 2: Effects with Arguments

Effects can pass data:

```flix
eff Logger {
    def log(message: String): Unit
}

def doWork(): Unit \ Logger = {
    Logger.log("Starting");
    Logger.log("Working...");
    Logger.log("Done")
}

def main(): Unit \ IO =
    run {
        doWork()
    } with handler Logger {
        def log(message, resume) = {
            println("[LOG] ${message}");
            resume()
        }
    }
```

Now `message` captures the string passed to `Logger.log()`.

### Step 3: Effects that Return Values

Effects can return data to the caller:

```flix
eff Config {
    def getTimeout(): Int32
}

def makeRequest(): Unit \ {Config, IO} = {
    let timeout = Config.getTimeout();
    println("Using timeout: ${timeout}ms")
}

def main(): Unit \ IO =
    run {
        makeRequest()
    } with handler Config {
        def getTimeout(_, resume) = resume(5000)
    }
```

Here `resume(5000)` returns the value 5000 to the code that called `Config.getTimeout()`.

### Step 4: Multiple Effects

Functions can use multiple effects, handled with chained handlers:

```flix
eff Logger {
    def log(msg: String): Unit
}

eff Config {
    def getDebugMode(): Bool
}

def initialize(): Unit \ {Logger, Config, IO} = {
    Logger.log("Initializing");
    if (Config.getDebugMode()) {
        println("Debug mode enabled")
    } else {
        ()
    }
}

def main(): Unit \ IO =
    run {
        initialize()
    } with handler Logger {
        def log(msg, resume) = { println(msg); resume() }
    } with handler Config {
        def getDebugMode(_, resume) = resume(true)
    }
```

### Step 5: Extracting Handlers into Functions

Inline handlers become unwieldy. Extract them:

```flix
def provideLogger(f: Unit -> a \ ef): a \ (ef - Logger) + IO =
    run { f() } with handler Logger {
        def log(msg, resume) = { println(msg); resume() }
    }

def provideConfig(f: Unit -> a \ ef): a \ (ef - Config) =
    run { f() } with handler Config {
        def getDebugMode(_, resume) = resume(true)
    }

def main(): Unit \ IO =
    run {
        initialize()
    } with provideLogger
      with provideConfig
```

The type signature `(ef - Logger) + IO` means: "Takes any effect set `ef`, removes `Logger` from it, and adds `IO`."

This pattern—handler functions chained with `with`—is the idiomatic "with provisions" style.

### Step 6: Effects with Multiple Operations

An effect can declare several operations:

```flix
eff Console {
    def readLine(): String
    def printLine(s: String): Unit
}

def interact(): Unit \ Console = {
    Console.printLine("What's your name?");
    let name = Console.readLine();
    Console.printLine("Hello, ${name}!")
}
```

The handler must implement ALL operations:

```flix
def main(): Unit \ IO =
    run {
        interact()
    } with handler Console {
        def readLine(_, resume) = {
            // In real code, read from stdin
            resume("Alice")
        }
        def printLine(s, resume) = {
            println(s);
            resume()
        }
    }
```

### Step 7: Composite Effects (Effects Using Effects)

One handler can invoke other effects:

```flix
eff BuyMilk { def buyMilk(): Unit }
eff BuyBread { def buyBread(): Unit }

eff GroceryList {
    def buyGroceries(): Unit
}

def provideGroceries(f: Unit -> a \ ef): a \ (ef - GroceryList) + {BuyMilk, BuyBread} =
    run { f() } with handler GroceryList {
        def buyGroceries(_, resume) = {
            BuyMilk.buyMilk();
            BuyBread.buyBread();
            resume()
        }
    }
```

The `GroceryList` handler produces `BuyMilk` and `BuyBread` effects, which must be handled separately. This enables hierarchical effect composition.

## Three Forms of Abstraction

Flix's effect system provides three distinct ways to structure and abstract your code:

### 1. Effect Composition (Structure)

Effects can be built from other effects. A handler for one effect can invoke operations from other effects:

```flix
eff BuyMilk { def buyMilk(): Unit }
eff BuyBread { def buyBread(): Unit }
eff GroceryList { def buyGroceries(): Unit }

def provideGroceries(f: Unit -> a \ ef): a \ (ef - GroceryList) + {BuyMilk, BuyBread} =
    run { f() } with handler GroceryList {
        def buyGroceries(_, resume) = {
            BuyMilk.buyMilk();    // Produces BuyMilk effect
            BuyBread.buyBread();  // Produces BuyBread effect
            resume()
        }
    }
```

This defines the *structure* of your effects—what an abstract operation means in terms of more primitive operations. It's analogous to defining interfaces and their relationships.

### 2. Handler Wiring (Configuration)

At program boundaries (typically `main`), you choose which concrete handlers to use:

```flix
def main(): Unit \ IO =
    run {
        doShopping()
    } with provideGroceries
      with provideMilk
      with provideBread
```

This is *configuration*—selecting implementations for your effects. Different programs (or tests) can wire the same effects differently:

```flix
// Production: real implementations
run { app() } with provideRealDatabase with provideRealLogger

// Testing: mock implementations
run { app() } with provideMockDatabase with provideTestLogger
```

This is analogous to dependency injection—the same code, different behaviors based on how it's wired.

### 3. Effect Polymorphism (Abstraction)

Functions can be generic over effects, working with any effect set:

```flix
def twice(f: Unit -> Unit \ ef): Unit \ ef = {
    f();
    f()
}

def retry(n: Int32, f: Unit -> a \ ef): a \ ef = {
    if (n <= 1) f()
    else {
        f()  // In real code, you'd handle failures
    }
}
```

The type variable `ef` represents *any* effect set. These functions don't care what effects `f` performs—they just pass them through. This is *abstraction*—writing code that's generic over effects.

Effect polymorphism is what makes handler extraction work:

```flix
def provideLogger(f: Unit -> a \ ef): a \ (ef - Logger) + IO = ...
//                          ^^                ^^
//                          |                 |
//                   accepts any effect  transforms it
```

The `ef` variable captures whatever effects the input has, and the return type expresses how those effects are transformed.

### How They Work Together

These three forms complement each other:

1. **Composition** defines your effect hierarchy (structure)
2. **Polymorphism** lets you write reusable handlers and utilities (abstraction)
3. **Wiring** connects everything at the program's entry point (configuration)

A typical program:
- Uses **composition** to define high-level effects in terms of low-level ones
- Uses **polymorphism** to write handler functions that work generically
- Uses **wiring** in `main` to select concrete implementations

```flix
// Composition: GroceryList uses BuyMilk and BuyBread
def provideGroceries(f: Unit -> a \ ef): a \ (ef - GroceryList) + {BuyMilk, BuyBread} = ...

// Polymorphism: works with any effect set
def provideMilk(f: Unit -> a \ ef): a \ (ef - BuyMilk) + IO = ...
def provideBread(f: Unit -> a \ ef): a \ (ef - BuyBread) + IO = ...

// Wiring: connect everything in main
def main(): Unit \ IO =
    run { doShopping() }
      with provideGroceries   // handles GroceryList, produces BuyMilk/BuyBread
      with provideMilk        // handles BuyMilk, produces IO
      with provideBread       // handles BuyBread, produces IO
```

## Important Syntax Details

### Handler Parameter Rules

Handler operation definitions infer types from the effect declaration. You must NOT add type annotations:

```flix
// CORRECT - no type annotations
with handler Logger {
    def log(message, resume) = { println(message); resume() }
}

// WRONG - will not compile
with handler Logger {
    def log(message: String, resume: Unit -> Unit): Unit = { ... }
}
```

This is different from normal Flix functions, which require type annotations:

```flix
def foo(x: Int32): Int32 = x + 1  // annotations required
```

Handler operations are a special case where Flix infers types from the effect declaration.

### Resumable vs Non-Resumable Effects

If an effect operation returns `Void`, it's non-resumable (like an exception):

```flix
eff Abort {
    def abort(message: String): Void
}

def mightFail(): Int32 \ Abort = {
    Abort.abort("Something went wrong")
    // Code here is unreachable
}

run {
    mightFail()
} with handler Abort {
    def abort(message, _resume) = {
        println("Aborted: ${message}")
        // Cannot call _resume - its argument type is Void
    }
}
```

The `_resume` prefix indicates an intentionally unused parameter. Since nothing can produce a `Void` value, the continuation can never be called.

### Handler Ordering Matters

Handlers are searched from innermost to outermost:

```flix
run {
    run {
        Logger.log("test")  // Uses "INNER" handler
    } with handler Logger {
        def log(msg, resume) = { println("INNER: ${msg}"); resume() }
    }
} with handler Logger {
    def log(msg, resume) = { println("OUTER: ${msg}"); resume() }
}
```

This is dynamic scoping—the nearest enclosing handler wins.

## Understanding Handler Dispatch

### It's Dynamic, But Compiled

When `Logger.log()` executes, Flix searches the runtime call stack for a matching handler. This is "dynamic scope."

But this doesn't mean interpretation. Flix compiles to JVM bytecode. The handler mechanism is compiled; only the *dispatch* (which handler to use) is determined at runtime.

Think of it like exception handling: `try/catch` blocks are compiled, but which `catch` handles a thrown exception depends on the runtime call stack.

### Type Safety at Compile Time

The compiler ensures all effects are handled before runtime:

```flix
def main(): Unit \ IO =
    run {
        Logger.log("test")  // ERROR: Logger effect not handled
    }
```

This won't compile. The type system guarantees that every effect has a handler, preventing "unhandled effect" runtime errors.

## Naming Conventions

The Flix standard library puts handlers in modules matching the effect name:

```flix
eff Clock { def currentTime(): Int64 }

mod Clock {
    pub def runWithIO(f: Unit -> a \ ef): a \ (ef - Clock) + IO = ...
}

// Usage
run { ... } with Clock.runWithIO
```

But this is just convention. There's no magic connection between `eff Clock` and `mod Clock`. You can organize handlers however you like:

```flix
// All handlers in one module
mod Handlers {
    pub def provideClock(f: Unit -> a \ ef): a \ (ef - Clock) + IO = ...
    pub def provideLogger(f: Unit -> a \ ef): a \ (ef - Logger) + IO = ...
}

// Or as top-level functions
def provideClock(f: Unit -> a \ ef): a \ (ef - Clock) + IO = ...
```

## Project Structure Note

Flix compiles all `.flix` files in `src/` into a single namespace. Top-level definitions can collide across files:

```
src/
  Main.flix      -> def helper() = ...
  Utils.flix     -> def helper() = ...  // COLLISION!
```

Use modules to namespace:

```flix
// Main.flix
mod Main { def helper() = ... }

// Utils.flix
mod Utils { def helper() = ... }  // No collision
```

## Summary: Why Use Effect Handlers?

1. **Explicit dependencies**: Function signatures reveal what effects they use
2. **Testability**: Swap handlers to mock effects in tests
3. **Flexibility**: Same code, different behaviors via different handlers
4. **Composability**: Multiple effects combine cleanly without monad transformers
5. **Type safety**: Compiler ensures all effects are handled
6. **Resumable control flow**: Handlers can continue execution, enabling powerful patterns

Effect handlers let you write code that describes *what* to do while deferring *how* to do it—a clean separation that makes code more modular, testable, and flexible.
