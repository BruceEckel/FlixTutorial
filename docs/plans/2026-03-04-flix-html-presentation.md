# Flix HTML Slideshow Presentation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a self-contained single-file HTML slideshow (`presentation.html`) that introduces Flix to experienced programmers, covering all 10 sections of the cheat sheet.

**Architecture:** One HTML file with all CSS and JavaScript inline. 19 slides driven by a minimal hand-rolled slide engine (~200 lines total). Keyboard navigation (←/→/Space/Home/End), fade transitions, slide counter, and a dark terminal-style code theme. No external dependencies.

**Tech Stack:** Vanilla HTML5, CSS3, JavaScript (ES6). No build tools, no CDN, no frameworks.

---

### Task 1: Scaffold the HTML shell and slide engine

**Files:**
- Create: `presentation.html`

**Step 1: Create the file with the base HTML, CSS, and JavaScript slide engine**

Write `presentation.html` with:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Introducing Flix</title>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: 'Segoe UI', system-ui, sans-serif;
  background: #1a1a2e;
  color: #eaeaea;
  height: 100vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.deck {
  flex: 1;
  position: relative;
  overflow: hidden;
}

.slide {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: flex-start;
  padding: 60px 80px;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s ease;
}

.slide.active {
  opacity: 1;
  pointer-events: auto;
}

/* Title slide */
.slide.title {
  align-items: center;
  text-align: center;
}

.slide.title h1 {
  font-size: 3.5rem;
  color: #e94560;
  margin-bottom: 0.4em;
}

.slide.title .subtitle {
  font-size: 1.4rem;
  color: #a0a0c0;
}

/* Section title slides */
.slide.section-title {
  background: #16213e;
  align-items: center;
  text-align: center;
}

.slide.section-title h2 {
  font-size: 2.8rem;
  color: #e94560;
}

/* Content slides */
h2 {
  font-size: 2rem;
  color: #e94560;
  margin-bottom: 0.6em;
  border-bottom: 2px solid #e9456033;
  padding-bottom: 0.3em;
  width: 100%;
}

h3 {
  font-size: 1.2rem;
  color: #a0a0c0;
  margin: 0.8em 0 0.3em;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

ul {
  list-style: none;
  margin: 0.5em 0;
}

ul li {
  padding: 0.3em 0;
  padding-left: 1.2em;
  position: relative;
  font-size: 1.05rem;
  line-height: 1.5;
}

ul li::before {
  content: '▸';
  color: #e94560;
  position: absolute;
  left: 0;
}

strong { color: #e2b96f; }

code {
  font-family: 'Cascadia Code', 'Fira Code', 'Consolas', monospace;
  font-size: 0.92em;
  background: #0f3460;
  border-radius: 3px;
  padding: 0.1em 0.35em;
}

pre {
  background: #0f3460;
  border: 1px solid #1e4a8a;
  border-radius: 6px;
  padding: 1em 1.2em;
  margin: 0.7em 0;
  overflow-x: auto;
  font-family: 'Cascadia Code', 'Fira Code', 'Consolas', monospace;
  font-size: 0.95rem;
  line-height: 1.6;
  color: #c9d1d9;
}

/* Syntax highlighting via spans */
.kw  { color: #ff79c6; }   /* keywords */
.ty  { color: #8be9fd; }   /* types */
.fn  { color: #50fa7b; }   /* function names */
.str { color: #f1fa8c; }   /* strings */
.cm  { color: #6272a4; font-style: italic; }  /* comments */
.num { color: #bd93f9; }   /* numbers */
.op  { color: #ff79c6; }   /* operators */
.eff { color: #ffb86c; }   /* effects */

table {
  border-collapse: collapse;
  margin: 0.5em 0;
  width: 100%;
  font-size: 0.95rem;
}

th {
  background: #16213e;
  color: #e94560;
  padding: 0.5em 0.8em;
  text-align: left;
  border: 1px solid #1e4a8a;
}

td {
  padding: 0.4em 0.8em;
  border: 1px solid #1e4a8a;
}

tr:nth-child(even) td { background: #16213e44; }

.two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2em;
  width: 100%;
}

/* Footer */
.footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 80px;
  background: #16213e;
  font-size: 0.85rem;
  color: #6272a4;
}

.counter { font-variant-numeric: tabular-nums; }

.nav-hint { color: #4a4a6a; }
</style>
</head>
<body>

<div class="deck" id="deck">
  <!-- SLIDES GO HERE -->
</div>

<div class="footer">
  <span class="nav-hint">← → Space · Home · End</span>
  <span class="counter" id="counter">1 / 1</span>
</div>

<script>
const slides = Array.from(document.querySelectorAll('.slide'));
let current = 0;

function show(n) {
  slides[current].classList.remove('active');
  current = Math.max(0, Math.min(n, slides.length - 1));
  slides[current].classList.add('active');
  document.getElementById('counter').textContent = `${current + 1} / ${slides.length}`;
}

document.addEventListener('keydown', e => {
  if (e.key === 'ArrowRight' || e.key === ' ')  show(current + 1);
  if (e.key === 'ArrowLeft')                     show(current - 1);
  if (e.key === 'Home')                          show(0);
  if (e.key === 'End')                           show(slides.length - 1);
});

// Touch support
let touchX = 0;
document.addEventListener('touchstart', e => touchX = e.touches[0].clientX);
document.addEventListener('touchend', e => {
  const dx = e.changedTouches[0].clientX - touchX;
  if (Math.abs(dx) > 50) show(current + (dx < 0 ? 1 : -1));
});

show(0);
</script>
</body>
</html>
```

**Step 2: Open the file in a browser and verify the engine works** (no slides yet — just the dark page with footer showing "1 / 1").

**Step 3: Commit**

```bash
git add presentation.html
git commit -m "feat: scaffold HTML slideshow engine with keyboard/touch nav"
```

---

### Task 2: Add title slide and "What is Flix?" slides (slides 1–2)

**Files:**
- Modify: `presentation.html` — replace `<!-- SLIDES GO HERE -->` with the first two slides

**Step 1: Add slide 1 (title) inside `<div class="deck">`**

```html
  <!-- Slide 1: Title -->
  <div class="slide title active">
    <h1>Introducing Flix</h1>
    <p class="subtitle">A functional-first language for the JVM</p>
    <p class="subtitle" style="margin-top:1.5em; font-size:1rem; color:#4a4a6a;">
      For programmers experienced with other languages
    </p>
  </div>
```

**Step 2: Add slide 2 (What is Flix?) after slide 1**

```html
  <!-- Slide 2: What is Flix? -->
  <div class="slide">
    <h2>What is Flix?</h2>
    <p style="margin-bottom:1em; color:#a0a0c0;">
      A statically typed, functional-first language for the JVM — drawing from
      OCaml, Haskell, Scala, and Rust, with four distinctive pillars:
    </p>
    <ul>
      <li><strong>Polymorphic effect system</strong> — side effects tracked in every type signature; pure functions are compiler-guaranteed pure</li>
      <li><strong>Algebraic effects &amp; handlers</strong> — user-defined effects with deep handlers; replaces monads and monad transformers</li>
      <li><strong>Region-based local mutation</strong> — pure functions can use internal mutation via scoped regions; mutable data cannot escape</li>
      <li><strong>Embedded Datalog</strong> — first-class Datalog constraints built into the language; inject, compute fixpoints, query results</li>
    </ul>
    <p style="margin-top:1em; color:#a0a0c0;">
      Hindley-Milner type inference: annotations required on top-level signatures,
      inferred within bodies.
    </p>
  </div>
```

**Step 3: Reload browser, verify 2 slides and navigation works.**

**Step 4: Commit**

```bash
git add presentation.html
git commit -m "feat: add title and What is Flix slides"
```

---

### Task 3: Add Getting Started slides (slides 3–4)

**Files:**
- Modify: `presentation.html` — append after slide 2

**Step 1: Add slide 3 (setup)**

```html
  <!-- Slide 3: Getting Started -->
  <div class="slide">
    <h2>Getting Started</h2>
    <h3>Prerequisites</h3>
    <ul><li>Java 21 or later</li></ul>
    <h3>Initialize a project</h3>
    <pre>$ mkdir my-project &amp;&amp; cd my-project
$ java -jar flix.jar init</pre>
    <p style="color:#a0a0c0; margin:0.5em 0;">Creates: <code>flix.toml</code>, <code>src/Main.flix</code>, <code>test/</code></p>
    <h3>Compiler commands</h3>
    <pre>$ java -jar flix.jar run      <span class="cm"># compile and run</span>
$ java -jar flix.jar check    <span class="cm"># type-check only</span>
$ java -jar flix.jar test     <span class="cm"># run @Test functions</span></pre>
  </div>
```

**Step 2: Add slide 4 (Hello World)**

```html
  <!-- Slide 4: Hello World -->
  <div class="slide">
    <h2>Hello World</h2>
    <pre><span class="kw">def</span> <span class="fn">main</span>(): <span class="ty">Unit</span> \ <span class="eff">IO</span> =
    <span class="fn">println</span>(<span class="str">"Hello World!"</span>)</pre>
    <ul>
      <li><code>main</code> takes <strong>no parameters</strong> — use <code>Environment.getArgs()</code> for CLI args</li>
      <li>Return type is <code>Unit</code> (like <code>void</code>)</li>
      <li><code>\ IO</code> is an <strong>effect annotation</strong> — part of the type, not a comment</li>
      <li>Pure functions <strong>omit</strong> the effect annotation entirely</li>
    </ul>
    <pre><span class="kw">def</span> <span class="fn">inc</span>(x: <span class="ty">Int32</span>): <span class="ty">Int32</span> = x + <span class="num">1</span>   <span class="cm">// pure — no \ IO</span></pre>
  </div>
```

**Step 3: Commit**

```bash
git add presentation.html
git commit -m "feat: add Getting Started and Hello World slides"
```

---

### Task 4: Add Types & Functions slides (slides 5–6)

**Files:**
- Modify: `presentation.html` — append after slide 4

**Step 1: Add slide 5 (Types & Variables)**

```html
  <!-- Slide 5: Types & Variables -->
  <div class="slide">
    <h2>Types &amp; Variables</h2>
    <div class="two-col">
      <div>
        <table>
          <tr><th>Type</th><th>Literal</th></tr>
          <tr><td><code>Bool</code></td><td><code>true</code>, <code>false</code></td></tr>
          <tr><td><code>Int32</code></td><td><code>42</code> (default int)</td></tr>
          <tr><td><code>Int64</code></td><td><code>42i64</code></td></tr>
          <tr><td><code>Float64</code></td><td><code>3.14</code> (default float)</td></tr>
          <tr><td><code>String</code></td><td><code>"hello"</code></td></tr>
          <tr><td><code>BigInt</code></td><td><code>42ii</code></td></tr>
          <tr><td><code>Unit</code></td><td><code>()</code></td></tr>
        </table>
      </div>
      <div>
        <h3>Let bindings (immutable)</h3>
        <pre><span class="kw">let</span> x = <span class="num">42</span>;
<span class="kw">let</span> y = x + <span class="num">1</span>;</pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin:0.5em 0;">All variables must be used. Prefix unused with <code>_</code>.</p>
        <h3>String interpolation</h3>
        <pre><span class="kw">let</span> name = <span class="str">"World"</span>;
<span class="str">"Hello ${name}!"</span></pre>
      </div>
    </div>
  </div>
```

**Step 2: Add slide 6 (Functions)**

```html
  <!-- Slide 6: Functions -->
  <div class="slide">
    <h2>Functions</h2>
    <div class="two-col">
      <div>
        <h3>Definition (curried by default)</h3>
        <pre><span class="kw">def</span> <span class="fn">add</span>(x: <span class="ty">Int32</span>, y: <span class="ty">Int32</span>): <span class="ty">Int32</span> = x + y

<span class="kw">def</span> <span class="fn">main</span>(): <span class="ty">Unit</span> \ <span class="eff">IO</span> =
    <span class="kw">let</span> inc = <span class="fn">add</span>(<span class="num">1</span>);  <span class="cm">// partial application</span>
    <span class="fn">inc</span>(<span class="num">42</span>) |> <span class="fn">println</span></pre>
        <h3>Lambdas</h3>
        <pre><span class="kw">let</span> inc = x -> x + <span class="num">1</span>;
<span class="kw">let</span> add = (x, y) -> x + y;</pre>
      </div>
      <div>
        <h3>Pipeline operator <code>|&gt;</code></h3>
        <pre><span class="str">"Hello World"</span>
  |> <span class="ty">String</span>.toUpperCase
  |> <span class="fn">println</span></pre>
        <h3>Function composition <code>&gt;&gt;</code></h3>
        <pre><span class="kw">let</span> h = f >> g  <span class="cm">// h(x) = g(f(x))</span></pre>
        <h3>Infix with backticks</h3>
        <pre><span class="num">123</span> `<span class="ty">Int32</span>.max` <span class="num">456</span></pre>
      </div>
    </div>
  </div>
```

**Step 3: Commit**

```bash
git add presentation.html
git commit -m "feat: add Types and Functions slides"
```

---

### Task 5: Add Data Types slides (slides 7–9)

**Files:**
- Modify: `presentation.html` — append after slide 6

**Step 1: Add slide 7 (Enums / ADTs)**

```html
  <!-- Slide 7: Enums -->
  <div class="slide">
    <h2>Enums (Algebraic Data Types)</h2>
    <div class="two-col">
      <div>
        <h3>Basic enum</h3>
        <pre><span class="kw">enum</span> <span class="ty">Shape</span> {
    <span class="kw">case</span> Circle(<span class="ty">Int32</span>)
    <span class="kw">case</span> Square(<span class="ty">Int32</span>)
    <span class="kw">case</span> Rectangle(<span class="ty">Int32</span>, <span class="ty">Int32</span>)
}</pre>
        <h3>Shorthand cases</h3>
        <pre><span class="kw">enum</span> <span class="ty">Weekday</span> {
    <span class="kw">case</span> Monday, Tuesday, Wednesday
    <span class="kw">case</span> Thursday, Friday, Saturday, Sunday
}</pre>
      </div>
      <div>
        <h3>Polymorphic enum</h3>
        <pre><span class="kw">enum</span> <span class="ty">Bottle</span>[a] {
    <span class="kw">case</span> Empty,
    <span class="kw">case</span> Full(a)
}</pre>
        <h3>Auto-derive traits</h3>
        <pre><span class="kw">enum</span> <span class="ty">Color</span> <span class="kw">with</span> <span class="ty">Eq</span>, <span class="ty">Order</span>, <span class="ty">ToString</span> {
    <span class="kw">case</span> Red, Green, Blue
}</pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin-top:0.5em;">Like <code>deriving</code> in Haskell, <code>#[derive]</code> in Rust</p>
      </div>
    </div>
  </div>
```

**Step 2: Add slide 8 (Records)**

```html
  <!-- Slide 8: Records -->
  <div class="slide">
    <h2>Records &amp; Row Polymorphism</h2>
    <div class="two-col">
      <div>
        <h3>Create &amp; access</h3>
        <pre><span class="kw">let</span> p = { x = <span class="num">1</span>, y = <span class="num">2</span> };
p#x + p#y</pre>
        <h3>Update (non-destructive)</h3>
        <pre><span class="kw">let</span> p2 = { x = <span class="num">3</span> | p };  <span class="cm">// p2 = {x=3, y=2}</span></pre>
      </div>
      <div>
        <h3>Row-polymorphic functions</h3>
        <pre><span class="kw">def</span> <span class="fn">getX</span>(r: {x = <span class="ty">Int32</span> | s}): <span class="ty">Int32</span> = r#x</pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin:0.5em 0;">Accepts any record with <em>at least</em> an <code>x</code> field.</p>
        <h3>Collections</h3>
        <pre><span class="kw">let</span> l = <span class="ty">List</span>#{<span class="num">1</span>, <span class="num">2</span>, <span class="num">3</span>};
<span class="kw">let</span> s = <span class="ty">Set</span>#{<span class="num">1</span>, <span class="num">2</span>, <span class="num">3</span>};
<span class="kw">let</span> m = <span class="ty">Map</span>#{<span class="num">1</span> => <span class="str">"one"</span>, <span class="num">2</span> => <span class="str">"two"</span>};
<span class="kw">let</span> l = <span class="num">1</span> :: <span class="num">2</span> :: <span class="num">3</span> :: Nil;</pre>
      </div>
    </div>
  </div>
```

**Step 3: Add slide 9 (Pattern Matching)**

```html
  <!-- Slide 9: Pattern Matching -->
  <div class="slide">
    <h2>Pattern Matching</h2>
    <div class="two-col">
      <div>
        <h3>Exhaustive match (compiler-enforced)</h3>
        <pre><span class="kw">def</span> <span class="fn">area</span>(s: <span class="ty">Shape</span>): <span class="ty">Int32</span> = <span class="kw">match</span> s {
    <span class="kw">case</span> <span class="ty">Shape</span>.Circle(r)       => <span class="num">3</span> * r * r
    <span class="kw">case</span> <span class="ty">Shape</span>.Square(w)       => w * w
    <span class="kw">case</span> <span class="ty">Shape</span>.Rectangle(h, w) => h * w
}</pre>
        <h3>Tuple destructuring</h3>
        <pre><span class="kw">let</span> (x, y, z) = (<span class="num">1</span>, <span class="num">2</span>, <span class="num">3</span>);</pre>
      </div>
      <div>
        <h3>Match lambdas</h3>
        <pre><span class="ty">List</span>.map(
  <span class="kw">match</span> (x, y) -> x + y,
  (<span class="num">1</span>, <span class="num">1</span>) :: (<span class="num">2</span>, <span class="num">2</span>) :: Nil
)</pre>
        <h3>No loops — use higher-order functions</h3>
        <pre><span class="ty">List</span>.range(<span class="num">1</span>, <span class="num">5</span>)
  |> <span class="ty">List</span>.map(x -> x * x)
  |> <span class="fn">println</span></pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin-top:0.5em;">No <code>for</code> or <code>while</code>. Use recursion, <code>List.map</code>, <code>foreach</code>, or <code>forM</code>.</p>
      </div>
    </div>
  </div>
```

**Step 4: Commit**

```bash
git add presentation.html
git commit -m "feat: add Enums, Records, and Pattern Matching slides"
```

---

### Task 6: Add Traits slide (slide 10)

**Files:**
- Modify: `presentation.html` — append after slide 9

**Step 1: Add slide 10 (Traits)**

```html
  <!-- Slide 10: Traits -->
  <div class="slide">
    <h2>Traits (Type Classes)</h2>
    <div class="two-col">
      <div>
        <h3>Declaring a trait</h3>
        <pre><span class="kw">trait</span> <span class="ty">Equatable</span>[t] {
    <span class="kw">pub def</span> <span class="fn">equals</span>(x: t, y: t): <span class="ty">Bool</span>
}</pre>
        <h3>Instance with constraint</h3>
        <pre><span class="kw">instance</span> <span class="ty">Equatable</span>[<span class="ty">Option</span>[t]]
    <span class="kw">with</span> <span class="ty">Equatable</span>[t] {
    <span class="kw">pub def</span> <span class="fn">equals</span>(x, y) = <span class="kw">match</span> (x, y) {
        <span class="kw">case</span> (None, None)         => <span class="kw">true</span>
        <span class="kw">case</span> (Some(a), Some(b)) => <span class="ty">Equatable</span>.<span class="fn">equals</span>(a, b)
        <span class="kw">case</span> _                    => <span class="kw">false</span>
    }
}</pre>
      </div>
      <div>
        <h3>Constrained function</h3>
        <pre><span class="kw">def</span> <span class="fn">memberOf</span>(x: t, l: <span class="ty">List</span>[t]): <span class="ty">Bool</span>
    <span class="kw">with</span> <span class="ty">Equatable</span>[t] = ...</pre>
        <h3>Standard library traits</h3>
        <table>
          <tr><th>Trait</th><th>Purpose</th></tr>
          <tr><td><code>Eq</code></td><td>Equality (<code>==</code>, <code>!=</code>)</td></tr>
          <tr><td><code>Order</code></td><td>Ordering (<code>&lt;</code>, <code>compare</code>)</td></tr>
          <tr><td><code>ToString</code></td><td>String conversion</td></tr>
          <tr><td><code>Hash</code></td><td>Hashing</td></tr>
        </table>
      </div>
    </div>
  </div>
```

**Step 2: Commit**

```bash
git add presentation.html
git commit -m "feat: add Traits slide"
```

---

### Task 7: Add Effect System slides (slides 11–14)

**Files:**
- Modify: `presentation.html` — append after slide 10

**Step 1: Add slide 11 (Pure vs. Impure)**

```html
  <!-- Slide 11: Effect System - Pure vs Impure -->
  <div class="slide">
    <h2>The Effect System</h2>
    <p style="color:#a0a0c0; margin-bottom:0.7em;">Flix's most distinctive feature. Three layers.</p>
    <h3>Layer 1: Pure vs. Impure</h3>
    <div class="two-col">
      <div>
        <pre><span class="cm">// Pure — no effect annotation</span>
<span class="kw">def</span> <span class="fn">inc</span>(x: <span class="ty">Int32</span>): <span class="ty">Int32</span> = x + <span class="num">1</span>

<span class="cm">// Impure — must declare \ IO</span>
<span class="kw">def</span> <span class="fn">greet</span>(name: <span class="ty">String</span>): <span class="ty">Unit</span> \ <span class="eff">IO</span> =
    <span class="fn">println</span>(<span class="str">"Hello ${name}!"</span>)</pre>
      </div>
      <div>
        <ul>
          <li>Pure functions are <strong>compiler-guaranteed pure</strong> — not by convention</li>
          <li>Omitting <code>\ IO</code> from an impure function is a <strong>compile error</strong></li>
          <li>Multiple effects: <code>\ {Eff1, Eff2}</code></li>
          <li>Explicit empty set: <code>\ { }</code></li>
        </ul>
      </div>
    </div>
  </div>
```

**Step 2: Add slide 12 (Effect Polymorphism)**

```html
  <!-- Slide 12: Effect Polymorphism -->
  <div class="slide">
    <h2>Effect Polymorphism</h2>
    <p style="color:#a0a0c0; margin-bottom:0.7em;">Higher-order functions propagate their argument's effects automatically.</p>
    <h3>List.map signature</h3>
    <pre><span class="kw">def</span> <span class="fn">map</span>(f: a -> b \ <span class="eff">ef</span>, l: <span class="ty">List</span>[a]): <span class="ty">List</span>[b] \ <span class="eff">ef</span></pre>
    <h3>In practice</h3>
    <pre><span class="cm">// Pure: ef = { }</span>
<span class="ty">List</span>.<span class="fn">map</span>(x -> x + <span class="num">1</span>, l)

<span class="cm">// Impure: ef = { IO }</span>
<span class="ty">List</span>.<span class="fn">map</span>(x -> { <span class="fn">println</span>(x); x + <span class="num">1</span> }, l)</pre>
    <ul>
      <li><code>List.map</code> is <strong>pure when given a pure function</strong>, impure when given an impure function</li>
      <li>The caller never thinks about it — it just works</li>
    </ul>
    <h3>Effect set algebra</h3>
    <table>
      <tr><th>Operation</th><th>Syntax</th><th>Meaning</th></tr>
      <tr><td>Union</td><td><code>ef1 + ef2</code></td><td>Has effects of both</td></tr>
      <tr><td>Intersection</td><td><code>ef1 &amp; ef2</code></td><td>Effects common to both</td></tr>
      <tr><td>Difference</td><td><code>ef1 - ef2</code></td><td>Effects of ef1 excluding ef2</td></tr>
    </table>
  </div>
```

**Step 3: Add slide 13 (Algebraic Effects & Handlers)**

```html
  <!-- Slide 13: Algebraic Effects -->
  <div class="slide">
    <h2>Algebraic Effects &amp; Handlers</h2>
    <div class="two-col">
      <div>
        <h3>Declare an effect</h3>
        <pre><span class="kw">eff</span> <span class="ty">DivByZero</span> {
    <span class="kw">def</span> <span class="fn">divByZero</span>(): <span class="ty">Void</span>  <span class="cm">// non-resumable</span>
}</pre>
        <h3>Use it</h3>
        <pre><span class="kw">def</span> <span class="fn">divide</span>(x: <span class="ty">Int32</span>, y: <span class="ty">Int32</span>):
    <span class="ty">Int32</span> \ <span class="eff">DivByZero</span> =
    <span class="kw">if</span> (y == <span class="num">0</span>) <span class="ty">DivByZero</span>.<span class="fn">divByZero</span>()
    <span class="kw">else</span> x / y</pre>
      </div>
      <div>
        <h3>Handle it</h3>
        <pre><span class="kw">def</span> <span class="fn">main</span>(): <span class="ty">Unit</span> \ <span class="eff">IO</span> =
    <span class="kw">run</span> {
        <span class="fn">println</span>(<span class="fn">divide</span>(<span class="num">3</span>, <span class="num">2</span>));
        <span class="fn">println</span>(<span class="fn">divide</span>(<span class="num">3</span>, <span class="num">0</span>))
    } <span class="kw">with handler</span> <span class="ty">DivByZero</span> {
        <span class="kw">def</span> <span class="fn">divByZero</span>(_resume) =
            <span class="fn">println</span>(<span class="str">"Oops: Division by Zero!"</span>)
    }</pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin-top:0.5em;">Handler eliminates the effect — <code>main</code> has <code>\ IO</code> only.</p>
      </div>
    </div>
  </div>
```

**Step 4: Add slide 14 (Resumable Effects)**

```html
  <!-- Slide 14: Resumable Effects -->
  <div class="slide">
    <h2>Resumable Effects</h2>
    <p style="color:#a0a0c0; margin-bottom:0.5em;">When an effect returns a non-<code>Void</code> type, the handler can resume the computation. Enables backtracking, cooperative multitasking, dependency injection, and more.</p>
    <div class="two-col">
      <div>
        <pre><span class="kw">eff</span> <span class="ty">Ask</span> { <span class="kw">def</span> <span class="fn">ask</span>(): <span class="ty">String</span> }
<span class="kw">eff</span> <span class="ty">Say</span> { <span class="kw">def</span> <span class="fn">say</span>(s: <span class="ty">String</span>): <span class="ty">Unit</span> }

<span class="kw">def</span> <span class="fn">greeting</span>(): <span class="ty">Unit</span> \ {<span class="eff">Ask</span>, <span class="eff">Say</span>} =
    <span class="kw">let</span> name = <span class="ty">Ask</span>.<span class="fn">ask</span>();
    <span class="ty">Say</span>.<span class="fn">say</span>(<span class="str">"Hello Mr. ${name}"</span>)</pre>
      </div>
      <div>
        <pre><span class="kw">def</span> <span class="fn">main</span>(): <span class="ty">Unit</span> \ <span class="eff">IO</span> =
    <span class="kw">run</span> {
        <span class="fn">greeting</span>()
    } <span class="kw">with handler</span> <span class="ty">Ask</span> {
        <span class="kw">def</span> <span class="fn">ask</span>(_, resume) =
            <span class="fn">resume</span>(<span class="str">"Bond, James Bond"</span>)
    } <span class="kw">with handler</span> <span class="ty">Say</span> {
        <span class="kw">def</span> <span class="fn">say</span>(s, resume) =
            { <span class="fn">println</span>(s); <span class="fn">resume</span>() }
    }
<span class="cm">// Output: Hello Mr. Bond, James Bond</span></pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin-top:0.5em;">A handler can call <code>resume</code> multiple times — enabling backtracking search.</p>
      </div>
    </div>
  </div>
```

**Step 5: Commit**

```bash
git add presentation.html
git commit -m "feat: add Effect System slides (pure/impure, polymorphism, handlers, resumable)"
```

---

### Task 8: Add Regions slide (slide 15)

**Files:**
- Modify: `presentation.html` — append after slide 14

**Step 1: Add slide 15 (Regions)**

```html
  <!-- Slide 15: Regions -->
  <div class="slide">
    <h2>Regions</h2>
    <p style="color:#a0a0c0; margin-bottom:0.5em;">Pure functions can use internal mutation via scoped regions. The compiler prevents mutable data from escaping. Think: Rust's borrow checker applied to a scoped arena, enforced by the type system.</p>
    <div class="two-col">
      <div>
        <h3>Pure sort with internal mutation</h3>
        <pre><span class="kw">def</span> <span class="fn">sort</span>(l: <span class="ty">List</span>[a]): <span class="ty">List</span>[a]
    <span class="kw">with</span> <span class="ty">Order</span>[a] =
    <span class="kw">region</span> rc {
        <span class="kw">let</span> arr = <span class="ty">List</span>.<span class="fn">toArray</span>(rc, l);
        <span class="ty">Array</span>.<span class="fn">sort</span>(arr);
        <span class="ty">Array</span>.<span class="fn">toList</span>(arr)
    }</pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin-top:0.5em;">No effect annotation — this function is <strong>pure</strong>.</p>
      </div>
      <div>
        <h3>Escape prevention (compile error)</h3>
        <pre><span class="kw">let</span> escaped = <span class="kw">region</span> rc {
    <span class="ty">Array</span>#{<span class="num">1</span>, <span class="num">2</span>, <span class="num">3</span>} @ rc   <span class="cm">// tied to rc</span>
};
<span class="cm">// ERROR: region variable 'rc' escapes its scope</span></pre>
        <h3>Pattern</h3>
        <ul>
          <li>Convert immutable input to mutable structure</li>
          <li>Mutate freely within <code>region rc { }</code></li>
          <li>Convert back to immutable output before returning</li>
        </ul>
      </div>
    </div>
  </div>
```

**Step 2: Commit**

```bash
git add presentation.html
git commit -m "feat: add Regions slide"
```

---

### Task 9: Add Embedded Datalog slide (slide 16)

**Files:**
- Modify: `presentation.html` — append after slide 15

**Step 1: Add slide 16 (Embedded Datalog)**

```html
  <!-- Slide 16: Embedded Datalog -->
  <div class="slide">
    <h2>Embedded Datalog</h2>
    <p style="color:#a0a0c0; margin-bottom:0.5em;">First-class Datalog constraints built into the language. Inject collections, compute fixpoints, query results — all within normal Flix functions.</p>
    <div class="two-col">
      <div>
        <h3>Graph reachability</h3>
        <pre><span class="kw">def</span> <span class="fn">isConnected</span>(s, src, dst) =
    <span class="kw">let</span> rules = #{
        Path(x, y) :- Edge(x, y).
        Path(x, z) :- Path(x, y), Edge(y, z).
    };
    <span class="kw">let</span> edges = inject s into Edge/<span class="num">2</span>;
    <span class="kw">let</span> paths = query edges, rules
        select <span class="kw">true</span> from Path(src, dst);
    not (<span class="ty">Vector</span>.<span class="fn">isEmpty</span>(paths))</pre>
      </div>
      <div>
        <h3>Key syntax</h3>
        <ul>
          <li><code>#{ ... }</code> — Datalog rules/facts as a value</li>
          <li><code>inject s into Edge/2</code> — fold any <code>Foldable</code> into relations</li>
          <li><code>query ... select expr from Pred(args)</code> — returns <code>Vector</code></li>
          <li>Constraints are <strong>row-polymorphic</strong> — composable values</li>
        </ul>
        <h3>Inject multiple collections</h3>
        <pre>inject names, jedis
    into Name/<span class="num">1</span>, Jedi/<span class="num">1</span></pre>
      </div>
    </div>
  </div>
```

**Step 2: Commit**

```bash
git add presentation.html
git commit -m "feat: add Embedded Datalog slide"
```

---

### Task 10: Add Modules, Testing, Java Interop, and Next Steps slides (slides 17–19)

**Files:**
- Modify: `presentation.html` — append final slides after slide 16

**Step 1: Add slide 17 (Modules & Testing)**

```html
  <!-- Slide 17: Modules & Testing -->
  <div class="slide">
    <h2>Modules &amp; Testing</h2>
    <div class="two-col">
      <div>
        <h3>Modules</h3>
        <pre><span class="kw">mod</span> <span class="ty">Math</span> {
    <span class="kw">pub def</span> <span class="fn">sum</span>(x: <span class="ty">Int32</span>, y: <span class="ty">Int32</span>): <span class="ty">Int32</span> =
        x + y
}

<span class="cm">// Use fully qualified</span>
<span class="ty">Math</span>.<span class="fn">sum</span>(<span class="num">1</span>, <span class="num">2</span>)

<span class="cm">// Or bring into scope</span>
<span class="kw">use</span> <span class="ty">Math</span>.sum;
<span class="fn">sum</span>(<span class="num">1</span>, <span class="num">2</span>)</pre>
        <p style="color:#a0a0c0; font-size:0.9rem; margin-top:0.5em;">No wildcard imports. Rename: <code>use A.{f => g}</code></p>
      </div>
      <div>
        <h3>Testing with <code>@Test</code></h3>
        <pre><span class="op">@Test</span>
<span class="kw">def</span> <span class="fn">testAdd</span>(): <span class="ty">Bool</span> = <span class="fn">add</span>(<span class="num">1</span>, <span class="num">2</span>) == <span class="num">3</span>

<span class="op">@Test</span>
<span class="kw">def</span> <span class="fn">testNeg</span>(): <span class="ty">Bool</span> = <span class="fn">add</span>(-<span class="num">1</span>, <span class="num">1</span>) == <span class="num">0</span></pre>
        <pre>$ java -jar flix.jar test</pre>
        <ul>
          <li>No arguments, return <code>Bool</code></li>
          <li><code>true</code> = pass, <code>false</code> = fail</li>
        </ul>
      </div>
    </div>
  </div>
```

**Step 2: Add slide 18 (Java Interop)**

```html
  <!-- Slide 18: Java Interop -->
  <div class="slide">
    <h2>Java Interop</h2>
    <div class="two-col">
      <div>
        <h3>Import, create, call</h3>
        <pre><span class="kw">import</span> java.io.File

<span class="kw">def</span> <span class="fn">main</span>(): <span class="ty">Unit</span> \ <span class="eff">IO</span> =
    <span class="kw">let</span> f = <span class="kw">new</span> <span class="ty">File</span>(<span class="str">"foo.txt"</span>);
    <span class="kw">if</span> (f.exists())
        <span class="fn">println</span>(<span class="str">"${f.getName()} exists!"</span>)
    <span class="kw">else</span>
        <span class="fn">println</span>(<span class="str">"${f.getName()} missing"</span>)</pre>
        <h3>Pure Java calls</h3>
        <pre><span class="kw">def</span> <span class="fn">hypotenuse</span>(x: <span class="ty">Float64</span>, y: <span class="ty">Float64</span>): <span class="ty">Float64</span> =
    <span class="kw">unsafe</span> <span class="ty">Math</span>.<span class="fn">sqrt</span>(<span class="ty">Math</span>.<span class="fn">pow</span>(x, <span class="num">2.0</span>) + <span class="ty">Math</span>.<span class="fn">pow</span>(y, <span class="num">2.0</span>))</pre>
      </div>
      <div>
        <h3>Type mapping</h3>
        <table>
          <tr><th>Flix</th><th>Java</th></tr>
          <tr><td><code>Bool</code></td><td><code>boolean</code></td></tr>
          <tr><td><code>Int32</code></td><td><code>int</code></td></tr>
          <tr><td><code>Int64</code></td><td><code>long</code></td></tr>
          <tr><td><code>Float64</code></td><td><code>double</code></td></tr>
          <tr><td><code>String</code></td><td><code>String</code></td></tr>
        </table>
        <p style="color:#a0a0c0; font-size:0.9rem; margin-top:0.5em;">Use <code>unsafe</code> to call Java from a pure context when you know the method has no side effects.</p>
      </div>
    </div>
  </div>
```

**Step 3: Add slide 19 (Next Steps)**

```html
  <!-- Slide 19: Next Steps -->
  <div class="slide title">
    <h1 style="font-size:2.8rem;">Next Steps</h1>
    <ul style="text-align:left; margin-top:1.5em; max-width:600px;">
      <li><strong>Documentation:</strong> <code>doc.flix.dev</code></li>
      <li><strong>API reference:</strong> <code>api.flix.dev</code></li>
      <li><strong>Standard library:</strong> <code>Option</code>, <code>Result</code>, <code>List</code>, <code>Set</code>, <code>Map</code>, <code>Vector</code>, <code>MutList</code>, <code>MutDeque</code></li>
      <li><strong>Monadic syntax:</strong> <code>forM</code> and <code>forA</code> for <code>Option</code>, <code>Result</code>, and applicative types</li>
      <li><strong>IDE support:</strong> VSCode extension, Neovim plugin, Emacs flix-mode</li>
      <li><strong>This cheat sheet:</strong> <code>FlixCheatSheet.md</code> in this repo</li>
    </ul>
    <p style="margin-top:2em; color:#4a4a6a;">Flix · flix.dev · Apache 2.0</p>
  </div>
```

**Step 4: Reload browser, verify all 19 slides and navigation.**

**Step 5: Commit**

```bash
git add presentation.html
git commit -m "feat: add Modules, Java Interop, and Next Steps slides — complete presentation"
```

---

### Task 11: Polish pass

**Files:**
- Modify: `presentation.html`

**Step 1: Verify all slides fit without horizontal scrolling at 1280×800** (standard projector resolution). Reduce font sizes on any overflowing slides via inline `style="font-size:0.85rem"` or by trimming code examples to essential lines.

**Step 2: Check slide counter updates correctly on first and last slide.**

**Step 3: Test keyboard navigation: Home/End, arrow keys, Space.**

**Step 4: Final commit**

```bash
git add presentation.html
git commit -m "polish: verify layout at 1280x800, trim overflowing slides"
```
