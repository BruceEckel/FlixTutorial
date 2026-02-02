# Flix: A Tutorial for Experienced Programmers

Flix is a functional-first programming language for the JVM.
It combines a Hindley-Milner type system with a polymorphic effect system,
region-based local mutation, and embedded Datalog constraints.
If you know Haskell, Scala, Rust, or OCaml, many ideas will feel familiar --
but Flix combines them in ways that are distinctly its own.

This tutorial covers the core of the language.
It is not exhaustive; see the [official documentation](https://doc.flix.dev/)
for the full reference.

## Table of Contents

1. [What is Flix?](#1-what-is-flix)
2. [Getting Started](#2-getting-started)
3. [Types, Variables, and Functions](#3-types-variables-and-functions)
4. [Data Types](#4-data-types)
5. [Pattern Matching and Control Flow](#5-pattern-matching-and-control-flow)
6. [Traits (Type Classes)](#6-traits-type-classes)
7. [The Effect System](#7-the-effect-system)
8. [Regions](#8-regions)
9. [Embedded Datalog](#9-embedded-datalog)
10. [Modules, Testing, Java Interop, and Next Steps](#10-modules-testing-java-interop-and-next-steps)

---

## 1. What is Flix?

Flix is a statically typed, functional-first language targeting the JVM.
Its design draws from OCaml, Haskell, Scala, and Rust, but several features
set it apart:

- **Polymorphic type and effect system.** Every function's side effects are
  tracked in its type signature. Pure functions are guaranteed pure by the
  compiler -- not by convention.

- **Algebraic effects and handlers.** Flix supports user-defined effects with
  deep, dynamically scoped handlers, similar to Koka and Eff. This replaces
  much of what you would use monads or monad transformers for in Haskell.

- **Region-based local mutation.** Pure functions can internally use mutable
  arrays, builders, and deques through scoped regions. The compiler prevents
  mutable data from escaping its region.

- **Embedded Datalog.** First-class Datalog constraints are built into the
  language. You can inject collections into relations, write rules, compute
  fixpoints, and query results -- all within ordinary Flix functions.

- **Hindley-Milner type inference.** Type annotations are required on
  top-level function signatures but inferred within function bodies, similar
  to OCaml and Haskell.

---

## 2. Getting Started

### Prerequisites

Flix requires **Java 21** or later:

```
$ java -version
```

### Project Setup

Create a directory and initialize a Flix project:

```
$ mkdir my-project && cd my-project
$ java -jar flix.jar init
```

This creates:
- `flix.toml` -- project configuration
- `src/Main.flix` -- the main source file
- `test/` -- test directory

### Hello World

Open `src/Main.flix`. The generated file contains:

```flix
def main(): Unit \ IO =
    println("Hello World!")
```

Three things to note:

1. `main` takes **no parameters**. Command-line arguments are available via
   `Environment.getArgs()`.
2. The return type is `Unit` (like `void` or `()`).
3. `\ IO` is an **effect annotation** -- it declares that `main` performs I/O.
   This is not a comment; it is part of the type. Pure functions omit it.

### Compiler Commands

```
$ java -jar flix.jar run       # compile and run
$ java -jar flix.jar check     # type-check without running
$ java -jar flix.jar test      # run @Test functions
```

---

## 3. Types, Variables, and Functions

### Primitive Types

| Type      | Description            | Literal Examples        |
|-----------|------------------------|-------------------------|
| `Bool`    | Boolean                | `true`, `false`         |
| `Char`    | Unicode character      | `'a'`, `'Z'`           |
| `Int8`    | 8-bit signed integer   | `42i8`                  |
| `Int16`   | 16-bit signed integer  | `42i16`                 |
| `Int32`   | 32-bit signed integer  | `42` (default)          |
| `Int64`   | 64-bit signed integer  | `42i64`                 |
| `Float32` | 32-bit float           | `3.14f32`               |
| `Float64` | 64-bit float           | `3.14` (default)        |
| `String`  | UTF-16 string          | `"hello"`               |
| `BigInt`  | Arbitrary-precision    | `42ii`                  |
| `Unit`    | The unit type          | `()`                    |

### Let Bindings

Variables are immutable and bound with `let`:

```flix
let x = 42;
let y = x + 1;
```

Flix enforces that all variables are used.
Prefix intentionally unused variables with `_`:

```flix
let _unused = compute();
```

### String Interpolation

Use `${}` inside double-quoted strings:

```flix
let name = "World";
let greeting = "Hello ${name}!";
```

### Function Definitions

Top-level functions require explicit type annotations:

```flix
def add(x: Int32, y: Int32): Int32 = x + y
```

Functions are **curried** by default (as in Haskell/OCaml):

```flix
def sum(x: Int32, y: Int32): Int32 = x + y

def main(): Unit \ IO =
    let inc = sum(1);
    inc(42) |> println
```

### Lambda Expressions

Lambdas use the arrow syntax:

```flix
let inc = x -> x + 1;
let add = (x, y) -> x + y;
```

### Pipeline and Composition

The pipeline operator `|>` passes the left value as the last argument
to the right function (similar to F# and Elixir):

```flix
"Hello World" |> String.toUpperCase |> println
```

Function composition with `>>` (like `>>>` in Haskell):

```flix
let f = x -> x + 1;
let g = x -> x * 2;
let h = f >> g;     // h(x) = g(f(x))
```

### Infix Calls

Any binary function can be called infix with backticks:

```flix
123 `Int32.max` 456
```

---

## 4. Data Types

### Enums (Algebraic Data Types)

Flix enums are ADTs, like `data` in Haskell or `enum` in Rust:

```flix
enum Shape {
    case Circle(Int32)
    case Square(Int32)
    case Rectangle(Int32, Int32)
}
```

Shorthand for simple cases:

```flix
enum Weekday {
    case Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
}
```

Singleton enum shorthand:

```flix
enum USD(Int32)
```

### Polymorphic Enums

Enums can be parameterized (like Haskell's `data Maybe a`):

```flix
enum Bottle[a] {
    case Empty,
    case Full(a)
}

def isEmpty(b: Bottle[a]): Bool = match b {
    case Bottle.Empty   => true
    case Bottle.Full(_) => false
}
```

### Recursive Types

```flix
enum Tree {
    case Leaf(Int32),
    case Node(Tree, Tree)
}

def sum(t: Tree): Int32 = match t {
    case Tree.Leaf(x)    => x
    case Tree.Node(l, r) => sum(l) + sum(r)
}
```

### Tuples

Tuples work as you would expect:

```flix
let pair = (1, "hello");
let triple = (1, 2, 3);
let (x, y, z) = triple;
```

### Records

Records are structurally typed with **row polymorphism** (similar to PureScript
or Elm's extensible records):

```flix
let p = { x = 1, y = 2 };
p#x + p#y
```

Access fields with `#`. Update fields by providing a new value with `| r`:

```flix
let p1 = { x = 1, y = 2 };
let p2 = { x = 3 | p1 };   // p2 = { x = 3, y = 2 }
```

Row-polymorphic functions accept records with *at least* the named fields:

```flix
def getX(r: {x = Int32 | s}): Int32 = r#x
```

This accepts `{ x = 1 }`, `{ x = 1, y = 2 }`, `{ x = 1, name = "hi" }`, etc.

### Collection Literals

```flix
let l = List#{1, 2, 3};
let s = Set#{1, 2, 3};
let m = Map#{1 => "one", 2 => "two"};
```

Alternatively, lists can be built with `::` and `Nil`:

```flix
let l = 1 :: 2 :: 3 :: Nil;
```

---

## 5. Pattern Matching and Control Flow

### Match Expressions

Pattern matching is exhaustive (the compiler rejects incomplete matches):

```flix
enum Animal {
    case Cat,
    case Dog,
    case Giraffe
}

def isTall(a: Animal): Bool = match a {
    case Animal.Cat     => false
    case Animal.Dog     => false
    case Animal.Giraffe => true
}
```

Matching enums with payloads:

```flix
def area(s: Shape): Int32 = match s {
    case Shape.Circle(r)       => 3 * (r * r)
    case Shape.Square(w)       => w * w
    case Shape.Rectangle(h, w) => h * w
}
```

### Matching Tuples

```flix
let (x, y, z) = (1, 2, 3);
```

### Matching Records

```flix
def getHeight(r: { height = Int32 | a }): Int32 = match r {
    case { height | _ } => height
}
```

### Match Lambdas

Destructure directly in a lambda with `match`:

```flix
List.map(match (x, y) -> x + y, (1, 1) :: (2, 2) :: Nil)
```

### If-Then-Else

`if` is an expression (like in OCaml/Haskell), not a statement:

```flix
let abs = if (x >= 0) x else -x;
```

### No Traditional Loops

Flix has no `for` or `while` loops. Use recursion, `List.map`, `List.forEach`,
`foreach`, or `forM` instead:

```flix
def factorial(n: Int32): Int32 =
    if (n <= 1) 1 else n * factorial(n - 1)
```

```flix
def main(): Unit \ IO =
    List.range(1, 5) |>
    List.map(x -> x * x) |>
    println
```

---

## 6. Traits (Type Classes)

Flix traits are type classes (like Haskell's typeclasses or Rust's traits).

### Declaring a Trait

```flix
trait Equatable[t] {
    pub def equals(x: t, y: t): Bool
}
```

Each trait has exactly one type parameter.

### Implementing Instances

```flix
instance Equatable[Option[t]] with Equatable[t] {
    pub def equals(x: Option[t], y: Option[t]): Bool =
        match (x, y) {
            case (None, None)         => true
            case (Some(v1), Some(v2)) => Equatable.equals(v1, v2)
            case _                    => false
        }
}
```

The `with Equatable[t]` clause is a **trait constraint** -- like `Eq a =>` in
Haskell or `where T: Eq` in Rust.

### Trait Constraints on Functions

```flix
def memberOf(x: t, l: List[t]): Bool with Equatable[t] =
    match l {
        case Nil     => false
        case y :: ys => Equatable.equals(x, y) or memberOf(x, ys)
    }
```

### Key Standard Library Traits

| Trait      | Purpose                        |
|------------|--------------------------------|
| `Eq`       | Equality (`==`, `!=`)          |
| `Order`    | Ordering (`<`, `>`, `compare`) |
| `ToString` | String conversion              |
| `Hash`     | Hashing                        |

### Automatic Derivation

Enums can derive common traits:

```flix
enum Color with Eq, Order, ToString {
    case Red,
    case Green,
    case Blue
}
```

This is analogous to `deriving (Eq, Ord, Show)` in Haskell or
`#[derive(PartialEq, Ord)]` in Rust.

---

## 7. The Effect System

The effect system is Flix's most distinctive feature. It has three layers.

### Layer 1: Pure vs. Impure

A function with no effect annotation is pure:

```flix
def inc(x: Int32): Int32 = x + 1
```

A function that performs I/O must declare `\ IO`:

```flix
def greet(name: String): Unit \ IO =
    println("Hello ${name}!")
```

You can also write the empty effect set explicitly as `\ { }`:

```flix
def inc(x: Int32): Int32 \ { } = x + 1
```

The compiler rejects mismatches -- you cannot omit `\ IO` from a function
that calls `println`.

### Layer 2: Effect Polymorphism

Higher-order functions propagate the effects of their arguments.
`List.map` has the signature:

```
def map(f: a -> b \ ef, l: List[a]): List[b] \ ef
```

The effect variable `ef` is unified with whatever effect the function
argument `f` has:

```flix
List.map(x -> x + 1, l)                // pure: ef = { }
List.map(x -> { println(x); x + 1}, l) // impure: ef = { IO }
```

This means `List.map` is pure when given a pure function and impure when
given an impure function. The caller never has to think about it.

Effect sets support algebraic operations:

| Operation      | Syntax     | Meaning                           |
|----------------|------------|-----------------------------------|
| Union          | `ef1 + ef2`| Has effects of both               |
| Intersection   | `ef1 & ef2`| Has effects common to both        |
| Difference     | `ef1 - ef2`| Has effects of `ef1` but not `ef2`|

### Layer 3: Algebraic Effects and Handlers

Flix supports user-defined effects in the style of Koka and Eff.
This is the most powerful layer.

#### Declaring an Effect

```flix
eff DivByZero {
    def divByZero(): Void
}
```

The `Void` return type means this is **non-resumable** -- once raised,
execution cannot continue from the call site (like a traditional exception).

#### Using an Effect

```flix
def divide(x: Int32, y: Int32): Int32 \ DivByZero =
    if (y == 0) {
        DivByZero.divByZero()
    } else {
        x / y
    }
```

The effect appears in the function's type: `Int32 \ DivByZero`.

#### Handling an Effect

```flix
def main(): Unit \ IO =
    run {
        println(divide(3, 2));
        println(divide(3, 0))
    } with handler DivByZero {
        def divByZero(_resume) = println("Oops: Division by Zero!")
    }
```

Output:
```
1
Oops: Division by Zero!
```

The `run { ... } with handler E { ... }` block handles effect `E`. Inside
the handler, `_resume` is the captured continuation. Since `divByZero`
returns `Void`, the continuation cannot be called (hence `_resume`).

The `DivByZero` effect is eliminated by the handler -- `main` has `\ IO`
(from `println`) but *not* `\ DivByZero`.

#### Resumable Effects

When an effect operation returns a non-`Void` type, the handler can
**resume** the computation:

```flix
eff Ask {
    def ask(): String
}

eff Say {
    def say(s: String): Unit
}

def greeting(): Unit \ {Ask, Say} =
    let name = Ask.ask();
    Say.say("Hello Mr. ${name}")

def main(): Unit \ IO =
    run {
        greeting()
    } with handler Ask {
        def ask(_, resume) = resume("Bond, James Bond")
    } with handler Say {
        def say(s, resume) = { println(s); resume() }
    }
```

Output:
```
Hello Mr. Bond, James Bond
```

The handler for `Ask` receives the continuation as `resume` and calls it
with a string value. The handler for `Say` prints the string and resumes.
Multiple effects are handled by chaining `with handler` clauses.

#### Multiple Resumptions

A handler can call `resume` more than once. This enables backtracking
search, cooperative multitasking, and similar patterns:

```flix
eff Amb {
    def flip(): Bool
}

def handleAmb(f: a -> b \ ef): a -> List[b] \ ef - Amb =
    x -> run {
        f(x) :: Nil
    } with handler Amb {
        def flip(_, resume) = resume(true) ::: resume(false)
    }
```

The `Amb` handler explores **both** branches by resuming with `true` and
`false`, then concatenating the results.

---

## 8. Regions

Regions let pure functions use internal mutation. All mutable data belongs
to a region that is tied to its lexical scope. When the scope ends, the
data becomes unreachable.

Think of it as Rust's borrow checker applied to a scoped arena allocator,
but enforced by the type system rather than a separate checker.

### Basic Usage

```flix
region rc {
    // rc is a region handle, in scope here
    // allocate mutable data associated with rc
}
// rc and all its data are gone
```

### Sorting with Regions

This function is **pure** despite using a mutable array internally:

```flix
def sort(l: List[a]): List[a] with Order[a] =
    region rc {
        let arr = List.toArray(rc, l);
        Array.sort(arr);
        Array.toList(arr)
    }
```

The pattern: convert to mutable structure, mutate, convert back.
The region `rc` is scoped to the block; the array cannot escape.

### StringBuilder with Regions

```flix
def toString(l: List[a]): String with ToString[a] =
    region rc {
        let sb = StringBuilder.empty(rc);
        List.forEach(x -> StringBuilder.appendString("${x} :: ", sb), l);
        StringBuilder.appendString("Nil", sb);
        StringBuilder.toString(sb)
    }
```

### Escape Prevention

The compiler prevents region-scoped data from leaking out:

```flix
def main(): Unit \ IO =
    let escaped = region rc {
        Array#{1, 2, 3} @ rc
    };
    println(escaped)
```

This produces a compile-time error:

```
>> The region variable 'rc' escapes its scope.
```

---

## 9. Embedded Datalog

Flix has first-class support for Datalog fixpoint computations.
You can define relations, write rules, inject data from collections,
and query results -- all within normal Flix functions.

### Graph Reachability

```flix
def isConnected(s: Set[(Int32, Int32)], src: Int32, dst: Int32): Bool =
    let rules = #{
        Path(x, y) :- Edge(x, y).
        Path(x, z) :- Path(x, y), Edge(y, z).
    };
    let edges = inject s into Edge/2;
    let paths = query edges, rules select true from Path(src, dst);
    not (paths |> Vector.isEmpty)

def main(): Unit \ IO =
    let s = Set#{(1, 2), (2, 3), (3, 4), (4, 5)};
    let src = 1;
    let dst = 5;
    if (isConnected(s, src, dst)) {
        println("Found a path between ${src} and ${dst}!")
    } else {
        println("Did not find a path between ${src} and ${dst}!")
    }
```

Key syntax elements:

- `#{ ... }` defines a set of Datalog rules or facts.
- `inject s into Edge/2` converts a `Set[(Int32, Int32)]` into binary
  `Edge` facts. The `/2` is the arity annotation.
- `query edges, rules select true from Path(src, dst)` computes the
  fixpoint and selects results. Returns a `Vector`.
- Predicate names (`Edge`, `Path`) are used directly -- no declaration needed.
- `src` and `dst` inside the query are the lexically bound function parameters.

### First-Class Constraints

Constraints are values. You can build them in separate functions and
compose them:

```flix
def getParents(): #{ ParentOf(String, String) | r } = #{
    ParentOf("Pompey", "Strabo").
    ParentOf("Gnaeus", "Pompey").
    ParentOf("Pompeia", "Pompey").
    ParentOf("Sextus", "Pompey").
}

def getAdoptions(): #{ AdoptedBy(String, String) | r } = #{
    AdoptedBy("Augustus", "Caesar").
    AdoptedBy("Tiberius", "Augustus").
}

def withAncestors(): #{ ParentOf(String, String),
                        AncestorOf(String, String) | r } = #{
    AncestorOf(x, y) :- ParentOf(x, y).
    AncestorOf(x, z) :- AncestorOf(x, y), AncestorOf(y, z).
}
```

The constraint types are **row-polymorphic** (the `| r`), so they can
be composed with other constraint sets that use additional predicates.

### Injecting from Collections

`inject` works with any `Foldable` -- lists, sets, maps, etc.:

```flix
let l = (1, 2) :: (2, 3) :: Nil;
let p = inject l into Edge/2;
```

Multiple collections can be injected simultaneously:

```flix
let names = "Lucky Luke" :: "Luke Skywalker" :: Nil;
let jedis = "Luke Skywalker" :: Nil;
let p = inject names, jedis into Name/1, Jedi/1;
```

---

## 10. Modules, Testing, Java Interop, and Next Steps

### Modules

Modules are declared with `mod`. Public definitions use `pub`:

```flix
mod Math {
    pub def sum(x: Int32, y: Int32): Int32 = x + y
}
```

Access with fully qualified names:

```flix
Math.sum(1, 2)
```

Or bring names into scope with `use`:

```flix
use Math.sum;
sum(1, 2)
```

Grouped and renamed imports:

```flix
use Math.{sum, mul};
use A.{concat => concatStrings};
```

Flix does **not** support wildcard imports.

Enums inside modules:

```flix
mod Zoo {
    pub enum Animal {
        case Cat,
        case Dog,
        case Fox
    }
}

def says(a: Zoo.Animal): String = match a {
    case Zoo.Animal.Cat => "Meow"
    case Zoo.Animal.Dog => "Woof"
    case Zoo.Animal.Fox => "Roar"
}
```

### Testing

Functions annotated with `@Test` are run by `java -jar flix.jar test`:

```flix
@Test
def testAdd(): Bool = add(1, 2) == 3

@Test
def testAddNegative(): Bool = add(-1, 1) == 0
```

Test functions take no arguments and return `Bool`.

### Java Interop

Flix runs on the JVM and can call Java directly.

**Importing and creating objects:**

```flix
import java.io.File

def main(): Unit \ IO =
    let f = new File("foo.txt");
    println(f.getName())
```

**Calling static methods:**

```flix
import java.lang.Math

def main(): Unit \ IO =
    println(Math.abs(-42i32))
```

**Calling instance methods:**

```flix
import java.io.File

def main(): Unit \ IO =
    let f = new File("foo.txt");
    if (f.exists())
        println("${f.getName()} exists!")
    else
        println("${f.getName()} does not exist!")
```

**Exception handling:**

```flix
import java.io.File
import java.io.FileWriter
import java.io.IOException

def main(): Unit \ IO =
    let f = new File("foo.txt");
    try {
        let w = new FileWriter(f);
        w.append("Hello World\n");
        w.close()
    } catch {
        case ex: IOException =>
            println("Error: ${ex.getMessage()}")
    }
```

**Pure Java calls with `unsafe`:**

If you know a Java method has no side effects, wrap it in `unsafe` to
call it from a pure context:

```flix
import java.lang.Math

def pythagoras(x: Float64, y: Float64): Float64 =
    unsafe Math.sqrt(Math.pow(x, 2.0) + Math.pow(y, 2.0))
```

**Type mapping:**

| Flix      | Java      |
|-----------|-----------|
| `Bool`    | `boolean` |
| `Char`    | `char`    |
| `Int8`    | `byte`    |
| `Int16`   | `short`   |
| `Int32`   | `int`     |
| `Int64`   | `long`    |
| `Float32` | `float`   |
| `Float64` | `double`  |
| `String`  | `String`  |

### Next Steps

- **Full documentation:** [doc.flix.dev](https://doc.flix.dev/)
- **API reference:** [api.flix.dev](https://api.flix.dev/)
- **Standard library:** Explore `Option`, `Result`, `List`, `Set`, `Map`,
  `Vector`, `MutList`, `MutDeque`, `MutMap`, and more.
- **Monadic syntax:** Flix supports `forM` and `forA` for working with
  `Option`, `Result`, and other monadic/applicative types.
- **IDE support:** VSCode extension, Neovim plugin, or Emacs flix-mode.
