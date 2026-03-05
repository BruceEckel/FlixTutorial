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
## 3. `lazy` and `force`: Built-In Lazy Evaluation
## 4. Lazy Data Structures: `DelayList`
## 5. The Reveal: Effect Handlers Were Delaying All Along
## 6. Controlling the Delay
## 7. Real Problems That Need Delay
## 8. Summary
