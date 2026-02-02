# Overview

AI-generated introduction to the Flix programming language.

## Project Structure

- `tutorial.md` -- 10-section introductory tutorial for experienced programmers (complete, all code verified)
- `docs/api.flix.dev/` -- API reference (HTML, from official site)
- `docs/doc.flix.dev/` -- Programming guide (HTML, from official site)
- `src/Main.flix` -- Default Hello World (Flix project initialized with `flix.jar init`)
- `flix.toml` -- Flix project config
- `flix.jar` -- Flix compiler

## Tutorial Status

`tutorial.md` is complete. It covers: What is Flix, Getting Started, Types/Variables/Functions,
Data Types (enums, records, collections), Pattern Matching, Traits, the Effect System
(pure/impure, effect polymorphism, algebraic effects and handlers), Regions,
Embedded Datalog, and Modules/Testing/Java Interop. All code examples were compiled
and run successfully with `java -jar flix.jar check` and `java -jar flix.jar run`.

## Flix Compiler Commands

The `flix` compiler is available in this directory as flix.jar and supports the following commands:

- `java -jar flix.jar init` - Initialize a new project (creates flix.toml, src/, test/)
- `java -jar flix.jar check` - Check code for errors
- `java -jar flix.jar run` - Run the project
- `java -jar flix.jar test` - Run @Test functions

## Key Flix Syntax Reference

Frequently needed syntax details (verified against docs and compiler):

- **Main**: `def main(): Unit \ IO = ...` (no args, Unit return, `\ IO` effect)
- **Effects**: `\ IO` after return type; pure functions omit it; `\ {Eff1, Eff2}` for multiple
- **Effect handlers**: `run { body } with handler EffName { def op(_resume) = ... }` (non-resumable) or `def op(arg, resume) = resume(value)` (resumable)
- **Algebraic effects**: `eff Name { def op(): ReturnType }` -- `Void` return = non-resumable
- **Regions**: `region rc { ... }` -- mutable data scoped to block; function stays pure
- **Datalog**: `#{ Rule(x,y) :- Fact(x,y). }` for rules; `inject coll into Pred/arity`; `query facts, rules select expr from Pred(args)` returns `Vector`
- **Records**: `{ x = 1, y = 2 }`, access `r#x`, update `{ x = 3 | r }`, row polymorphism `{x = Int32 | s}`
- **Enums**: `enum Name { case A, case B(Int32) }`, derive with `enum Name with Eq, Order, ToString { ... }`
- **Traits**: `trait Name[t] { pub def ... }`, instances `instance Name[Type] with Constraint[t] { ... }`
- **Modules**: `mod Name { pub def ... }`, `use Name.func`, no wildcard imports
- **Java interop**: `import java.pkg.Class`, `new Class(args)`, call methods directly, `unsafe` for pure Java calls

## Documentation Reference

Key doc pages in `docs/doc.flix.dev/`:

- `hello-world.html` -- Hello World syntax
- `getting-started.html` -- Project setup
- `functions.html` -- Functions, lambdas, pipelines
- `enums.html` -- Enum/ADT definitions
- `records.html` -- Records and row polymorphism
- `pattern-matching.html` -- Match expressions
- `traits.html` -- Traits and instances
- `effect-system.html` -- Core effect system concepts
- `effect-polymorphism.html` -- Effect polymorphism
- `effects-and-handlers.html` -- Algebraic effects and handlers
- `regions.html` -- Region-based local mutation
- `fixpoints.html` -- Embedded Datalog
- `modules.html` -- Modules, use, pub
- `interoperability.html` -- Java interop overview
- `calling-methods.html` -- Calling Java methods
- `creating-objects.html` -- Creating Java objects
