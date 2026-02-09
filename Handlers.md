# Flix Effect Handlers

Every useful program interacts with the world: reading files, printing output, generating random numbers, making network requests. 
These interactions are called *side effects*, and they create several problems:

1. **Hidden dependencies**: A function that reads a config file has an implicit dependency on the file system, but its signature doesn't reveal this.

2. **Testing difficulty**: How do you test a function that sends emails? You don't want to actually send emails during tests.

3. **Inflexibility**: Code that directly calls `println` can only print to the console. What if you want to capture output for logging, or redirect it?

4. **Reasoning challenges**: When functions can do anything, it's hard to know what they'll actually do.

## Traditional Solutions

**Exceptions** handle error cases but only propagate upward. They're non-resumable—once thrown, you can't continue from where you left off.

**Dependency injection** passes services as parameters, but leads to parameter bloat and boilerplate.

**Monads** (as in Haskell) provide type-safe effect tracking but require awkward transformers when combining multiple effects, and the order of monad stacking matters.

## Algebraic Effects

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

The same `processData` function can be used with different handlers:

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

## Handlers Step-by-Step

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
- The handler must have the same name as the effect it handles
- `main` provides the handler using the syntax `run { ... } with handler Greet { ... }`
- The handler's `def sayHello(_, resume)` has two parameters:
  - `_` for the operation's arguments (none here, so ignored)
  - `resume` is the continuation; calling it returns to where `sayHello()` was invoked

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
Because `makeRequest` calls `println` the signature includes both `Config` and `IO`.

How does the compiler know `resume` takes an `Int32`? It infers the signature from the effect declaration:

```flix
eff Config {
    def getTimeout(): Int32  // returns Int32
}
```

The rule is:
- **First handler param** (`_`): matches the operation's *arguments* (here: none, so `Unit`)
- **`resume` param**: takes the operation's *return type* as its argument (here: `Int32`)

So `resume` has type `Int32 -> Unit`. 
The effect declaration is the "contract" that tells the compiler what types flow in (operation arguments) and out (via resume).

A more complex example:

```flix
eff Database {
    def query(sql: String): List[Row]
}

def fetchUsers(): List[Row] \ Database =
    Database.query("SELECT * FROM users")

def main(): Unit \ IO =
    run {
        let users = fetchUsers();
        println("Found ${List.length(users)} users")
    } with handler Database {
        def query(sql, resume) = {
            // sql : String               (from operation's argument)
            // resume : List[Row] -> ...  (from operation's return type)
            let results = actualQuery(sql);
            resume(results)
        }
    }
```

Note: `with handler` must always be attached to a `run { ... }` block. There are no standalone or default handlers.

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

### Runtime Handler Selection

Since dispatch is dynamic, you can choose handlers based on runtime values:

```flix
def verboseLogger(f: Unit -> a \ ef): a \ (ef - Logger) + IO =
    run { f() } with handler Logger {
        def log(msg, resume) = { println("[VERBOSE] ${msg}"); resume() }
    }

def quietLogger(f: Unit -> a \ ef): a \ (ef - Logger) + IO =
    run { f() } with handler Logger {
        def log(_, resume) = resume()  // discard logs
    }

def main(): Unit \ IO =
    let debugMode = true;  // could come from config, env var, etc.
    if (debugMode)
        run { doWork() } with verboseLogger
    else
        run { doWork() } with quietLogger
```

The compiler only requires that *all branches* handle the effects. It doesn't care which handler actually runs. This gives you runtime flexibility while maintaining compile-time safety.

### Dynamic Binding: The Mechanism

Effect handlers use dynamic binding—the connection between an effect operation and its handler is resolved at runtime, not compile time.

When `Logger.log("hello")` executes:

1. Runtime searches up the call stack for `handler Logger { ... }`
2. Finds the nearest enclosing handler
3. Invokes that handler's `log` implementation
4. Handler calls `resume()` to return control

This is similar to other dynamic dispatch mechanisms:

| Mechanism | Lookup |
|-----------|--------|
| Virtual methods (OOP) | vtable pointer → method |
| Exceptions | stack search → nearest catch |
| Effect handlers | stack search → nearest handler |

The key difference from lexical (static) scoping:

```flix
def inner(): Unit \ Logger =
    Logger.log("test")

def outer1(): Unit \ IO =
    run { inner() } with handler Logger {
        def log(msg, k) = { println("A: ${msg}"); k() }
    }

def outer2(): Unit \ IO =
    run { inner() } with handler Logger {
        def log(msg, k) = { println("B: ${msg}"); k() }
    }
```

`inner()` is defined once but gets different handlers depending on who calls it. The binding isn't determined by where `inner` is written (lexical), but by the runtime call stack (dynamic).

This dynamic indirection is the cost you pay for flexibility. In practice, JVM JIT compilation can often optimize common paths.

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

## Alternatives: Life Without Handlers

You can achieve similar goals without effect handlers. Here's how the same problem looks with traditional approaches:

### Direct Functions

The simplest approach—just regular functions with IO:

```flix
def buyMilk(): Unit \ IO = println("Buying milk")
def buyBread(): Unit \ IO = println("Buying bread")

def buyGroceries(): Unit \ IO = {
    buyMilk();
    buyBread()
}

def main(): Unit \ IO = buyGroceries()
```

**Tradeoff**: Simple, but no flexibility. Testing requires calling real IO.

### Dependency Injection via Records

Pass implementations as a record parameter:

```flix
type alias GroceryActions = {
    buyMilk = Unit -> Unit \ IO,
    buyBread = Unit -> Unit \ IO
}

def buyGroceries(actions: GroceryActions): Unit \ IO = {
    actions#buyMilk();
    actions#buyBread()
}

// Production
def realActions(): GroceryActions = {
    buyMilk = () -> println("Buying milk"),
    buyBread = () -> println("Buying bread")
}

// Test
def testActions(): GroceryActions = {
    buyMilk = () -> println("[TEST] milk"),
    buyBread = () -> println("[TEST] bread")
}

def main(): Unit \ IO = buyGroceries(realActions())
```

**Tradeoff**: Flexible and testable, but every function must explicitly pass the record. Parameter bloat accumulates.

### Traits (Interface-Based)

Use traits for polymorphism:

```flix
trait GroceryStore[s] {
    pub def buyMilk(store: s): Unit \ IO
    pub def buyBread(store: s): Unit \ IO
}

enum RealStore { case RealStore }
enum TestStore { case TestStore }

instance GroceryStore[RealStore] {
    pub def buyMilk(_: RealStore): Unit \ IO = println("Buying milk")
    pub def buyBread(_: RealStore): Unit \ IO = println("Buying bread")
}

instance GroceryStore[TestStore] {
    pub def buyMilk(_: TestStore): Unit \ IO = println("[TEST] milk")
    pub def buyBread(_: TestStore): Unit \ IO = println("[TEST] bread")
}

def buyGroceries(store: s): Unit \ IO with GroceryStore[s] = {
    GroceryStore.buyMilk(store);
    GroceryStore.buyBread(store)
}

def main(): Unit \ IO = buyGroceries(RealStore.RealStore)
```

**Tradeoff**: Type-safe and flexible, but requires passing a witness value and more boilerplate.

### Comparison Table

| Approach | Flexibility | Testability | Boilerplate | Composability |
|----------|-------------|-------------|-------------|---------------|
| Direct functions | Low | Low | Minimal | N/A |
| Record injection | High | High | Medium (parameter passing) | Manual |
| Traits | High | High | Medium (instances) | Via constraints |
| Effect handlers | High | High | Low | Built-in |

### Why Handlers Win

Effect handlers give you the flexibility of dependency injection without the parameter threading:

```flix
// Record injection: must pass 'actions' everywhere
def step1(actions: Actions): Unit \ IO = ...
def step2(actions: Actions): Unit \ IO = { step1(actions); ... }
def step3(actions: Actions): Unit \ IO = { step2(actions); ... }

// Effect handlers: effects are implicit
def step1(): Unit \ Actions = ...
def step2(): Unit \ Actions = { step1(); ... }
def step3(): Unit \ Actions = { step2(); ... }

// Provide once at the boundary
run { step3() } with provideActions
```

Effect handlers are "dependency injection without the injection"—dependencies are declared in types but provided once at the boundary, not threaded through every call.

## Summary: Why Use Effect Handlers?

1. **Explicit dependencies**: Function signatures reveal what effects they use
2. **Testability**: Swap handlers to mock effects in tests
3. **Flexibility**: Same code, different behaviors via different handlers
4. **Composability**: Multiple effects combine cleanly without monad transformers
5. **Type safety**: Compiler ensures all effects are handled
6. **Resumable control flow**: Handlers can continue execution, enabling powerful patterns

Effect handlers let you write code that describes *what* to do while deferring *how* to do it—a clean separation that makes code more modular, testable, and flexible.
