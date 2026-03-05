# A Gentle Introduction to Delayed Execution in Flix

In the previous chapter we met side effects and effect handlers — Flix's way of describing and controlling what a function is allowed to do. Now we go deeper into a related idea: sometimes you don't want computation to happen immediately at all. Flix offers three distinct mechanisms for delaying execution, each more powerful than the last, and understanding how they relate to one another unlocks a clearer mental model of the whole language. This chapter is purely orientation; code examples come in the sections that follow.

## 1. What Does "Delay" Mean?
## 2. Thunks: The Simplest Delay
## 3. `lazy` and `force`: Built-In Lazy Evaluation
## 4. Lazy Data Structures: `DelayList`
## 5. The Reveal: Effect Handlers Were Delaying All Along
## 6. Controlling the Delay
## 7. Real Problems That Need Delay
## 8. Summary
