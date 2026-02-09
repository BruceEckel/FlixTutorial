# Flix Effect System Learnings

## Effect Handler Syntax

The correct syntax for effect handlers is:

```flix
run { body } with handler EffectName {
    def operationName(_, resume) = { ...; resume() }
}
```

Key points:
- Handler parameters do NOT take type annotations (see below for why)
- Use `{ ... }` braces for handler bodies with multiple statements
- For resumable effects (return type is not `Void`), use `(_, resume)` where `_` is the operation's arguments and `resume` is the continuation
- For non-resumable effects (return type is `Void`), use `(_resume)` - a single unused continuation parameter

## Chaining Multiple Handlers

Multiple handlers can be chained on a single `run` block:

```flix
run {
    doSomething()
} with handler Effect1 {
    def op1(_, resume) = { ...; resume() }
} with handler Effect2 {
    def op2(_, resume) = { ...; resume() }
}
```

## The "With Provisions" Style

Handlers can be extracted into functions and chained with `with`:

```flix
def provideEffect(f: Unit -> a \ ef): a \ (ef - Effect) + IO =
    run { f() } with handler Effect {
        def operation(_, resume) = { ...; resume() }
    }

def main(): Unit \ IO =
    run {
        doSomething()
    } with provideEffect
      with provideOtherEffect
```

## Naming Conventions

- `runWithIO` is just a naming convention used by the Flix standard library, not a special keyword
- You can use any name: `provide`, `handle`, `run`, etc.
- The standard library uses `runWithIO` for running a thunk and `handle` for wrapping functions

## Effects with Multiple Operations

An effect can declare multiple operations:

```flix
eff Console {
    def readln(): String
    def println(s: String): Unit
}
```

A single handler must implement ALL operations in that effect:

```flix
run { ... } with handler Console {
    def readln(_, resume) = { ...; resume(input) }
    def println(s, resume) = { ...; resume() }
}
```

## No Magic Connection Between Effect and Handler Module

Having `eff BuyMilk` and `mod BuyMilk` with the same name is just a convention for organization. The actual binding happens via `with handler BuyMilk` in the function body:

```flix
mod BuyMilk {
    pub def provide(f: Unit -> a \ ef): a \ (ef - BuyMilk) + IO =
        run { f() } with handler BuyMilk {  // <-- binding happens here
            def buyMilk(_, resume) = { ...; resume() }
        }
}
```

## Handlers Don't Need Modules

Handlers can be top-level functions:

```flix
def provideMilk(f: Unit -> a \ ef): a \ (ef - BuyMilk) + IO =
    run { f() } with handler BuyMilk {
        def buyMilk(_, resume) = { println("Buying milk"); resume() }
    }

def main(): Unit \ IO =
    run { ... } with provideMilk
```

## Type Annotations in Flix

Handler parameters don't need type annotations because Flix infers them from the effect declaration:

```flix
eff BuyMilk {
    def buyMilk(): Unit  // defines the signature
}

with handler BuyMilk {
    def buyMilk(_, resume) = ...  // types inferred from effect
}
```

This is a special case. Normal Flix rules for type annotations:

**Top-level functions require annotations:**
```flix
def foo(x: Int32): Int32 = x + 1  // required

def bar(x) = x + 1  // error: missing type
```

**Lambdas can infer types from context:**
```flix
List.map(x -> x + 1, List#{1, 2, 3})  // x inferred as Int32
```

So handler operation definitions are similar to lambdas - they have enough context (the effect declaration) to infer parameter types.

## If-Else Expressions

In Flix, `if` is an expression and both branches must have the same type. When the result type is `Unit`, you can omit the `else` clause, but only if the body is enclosed in curly braces:

```flix
// OK - curly braces allow omitting else
if (cond) {
    println("yes")
}

// ERROR - no braces requires else
if (cond)
    println("yes")

// OK - explicit else with Unit value
if (cond)
    println("yes")
else
    ()
```

## Type Signatures vs Handler Binding

The type signature `(ef - BuyMilk)` describes what the function does (removes `BuyMilk` from the effect set). The actual handler binding is done by `with handler BuyMilk { ... }`.

The type system verifies that your implementation matches your claimed signature.

## Dynamic Handler Lookup (But Compiled)

Handler lookup is dynamic at runtime - when an effect operation is called, Flix searches up the call stack for the nearest matching handler. This is "dynamic scope."

However, the code is fully compiled (to JVM bytecode). "Dynamic" refers to the lookup behavior, not interpretation. It's similar to how exception try/catch works - compiled code, but which catch block handles an exception depends on the runtime call stack.

Inner handlers shadow outer handlers:

```flix
run {
    run {
        BuyMilk.buyMilk()  // uses inner "Skim" handler
    } with handler BuyMilk { def buyMilk(_, r) = { println("Skim"); r() } }
} with handler BuyMilk { def buyMilk(_, r) = { println("Whole"); r() } }
```

## Project Structure and Namespaces

Flix compiles all `.flix` files in `src/` as a single compilation unit. All top-level definitions share the root namespace.

To avoid collisions between files, use modules:

```flix
// File1.flix
mod File1 {
    def foo() = ...
}

// File2.flix
mod File2 {
    def foo() = ...  // no collision
}
```

There's no implicit namespace per file or directory - namespacing requires explicit `mod` declarations.
