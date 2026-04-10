---
name: spec
description: "Write function specs only — no implementation. Outputs structured doc (Task, Why, Invariants) + signature + TODO. For design review and LoRA training data. Triggers: spec mode, start spec, stop spec, design only, no code."
license: MIT
compatibility: opencode
metadata:
  category: workflow
---

# spec — Design-First Spec Mode

## Persistence

ACTIVE EVERY RESPONSE once enabled. Off only: "stop spec" or "spec off".

## Behavior

When active: **never write function/method bodies**. Only output:

1. Structured doc comment (Task, Why, Invariants, Example, Errors, Complexity — whichever apply)
2. Full type signature
3. `// TODO` body placeholder

This applies to ALL code generation — new functions, refactors, implementations.

## Output Format

### Rust
```rust
/// # Task
/// <what this function does — one line>
///
/// # Why
/// <motivation — why this exists, what problem it solves>
///
/// # Invariants
/// - <constraint 1>
/// - <constraint 2>
///
/// # Errors
/// - Returns `Err(X)` when <condition>
///
/// # Complexity
/// O(n)
///
/// # Example
/// ```rust
/// let result = do_thing(input)?;
/// assert_eq!(result, expected);
/// ```
pub fn do_thing(input: InputType) -> Result<OutputType, ErrorType> {
    // TODO
}
```

### Haskell
```haskell
-- | Task: <what this function does>
-- | Why: <motivation>
-- | Invariants:
-- |   - <constraint 1>
-- |   - <constraint 2>
-- | Complexity: O(n)
-- | Example: doThing [1,2,3] == 6
doThing :: [Int] -> Int
doThing = undefined -- TODO
```

### Scala
```scala
/**
 * Task: <what this function does>
 * Why: <motivation>
 * Invariants:
 *   - <constraint 1>
 *   - <constraint 2>
 * Errors: throws X when Y
 * Complexity: O(n)
 * Example: doThing(List(1,2,3)) == 6
 */
def doThing(input: List[Int]): Int = ??? // TODO
```

### TypeScript / JavaScript
```typescript
/**
 * Task: <what this function does>
 * Why: <motivation>
 * Invariants:
 *   - <constraint 1>
 *   - <constraint 2>
 * Throws: X when Y
 * Complexity: O(n)
 * @example
 * const result = doThing(input);
 * // => expected
 */
function doThing(input: InputType): OutputType {
  // TODO
}
```

## Doc Fields

Use whichever fields are relevant. Not all required every time.

| Field | When to include |
|---|---|
| Task | ALWAYS — what it does |
| Why | ALWAYS — motivation, context |
| Invariants | when preconditions/postconditions exist |
| Errors | when function can fail |
| Complexity | when non-obvious (skip for trivial O(1)) |
| Example | when usage is non-obvious |

## Rules

1. **Signature must be complete** — full types, generics, bounds, lifetimes. No shortcuts.
2. **Body is always TODO** — never write logic, even trivial one-liners.
3. **Multiple functions OK** — if task needs multiple fns, spec all of them.
4. **Imports/types OK** — type definitions, structs, enums, traits CAN be fully written. Only function/method bodies are TODO.
5. **Tests** — spec test functions too (write test name + doc of what it verifies, body = TODO).
6. **Existing code** — when asked to modify existing code, output the new spec for changed functions only.

## What IS allowed fully (no TODO)

- Type definitions (struct, enum, trait, typeclass, case class) — **with structured doc**
- Constant declarations — **with doc**
- Module/package structure
- Import statements
- Config files, TOML, YAML, JSON

Only **function/method bodies** are restricted to TODO.

## Type/Struct/Enum Doc Format

Types get full body BUT must have structured doc. Fields = output, doc = instruction.

### Rust
```rust
/// # Task
/// Represents a payment event from webhook.
///
/// # Why
/// Normalize Stripe's stringly-typed JSON into typed domain model.
///
/// # Invariants
/// - `amount` always in smallest currency unit (cents)
/// - `event_id` globally unique, used for dedup
/// - `timestamp` is UTC, never local
pub struct PaymentEvent {
    pub event_id: Uuid,
    pub kind: EventKind,
    pub amount: u64,
    pub currency: Currency,
    pub timestamp: DateTime<Utc>,
}
```

### Haskell
```haskell
-- | Task: Represents a payment event from webhook
-- | Why: Normalize untyped JSON into domain model
-- | Invariants:
-- |   - amount in smallest currency unit
-- |   - eventId globally unique
data PaymentEvent = PaymentEvent
  { eventId   :: UUID
  , kind      :: EventKind
  , amount    :: Word64
  , currency  :: Currency
  , timestamp :: UTCTime
  }
```

### Scala
```scala
/**
 * Task: Represents a payment event from webhook.
 * Why: Normalize untyped JSON into typed domain model.
 * Invariants:
 *   - amount in smallest currency unit (cents)
 *   - eventId globally unique, used for dedup
 */
case class PaymentEvent(
    eventId: UUID,
    kind: EventKind,
    amount: Long,
    currency: Currency,
    timestamp: Instant
)
```

### Enum/ADT
```rust
/// # Task
/// All possible webhook event types from Stripe.
///
/// # Why
/// Closed set — compiler enforces exhaustive matching.
///
/// # Invariants
/// - Must stay in sync with Stripe API docs
/// - Unknown events rejected at parse time, never stored
pub enum EventKind {
    PaymentSucceeded,
    PaymentFailed,
    RefundCreated,
    DisputeOpened,
}
```

## Doc Fields for Types

| Field | When to include |
|---|---|
| Task | ALWAYS — what this type represents |
| Why | ALWAYS — why it exists, what problem it models |
| Invariants | ALWAYS for types — field constraints, valid states |
| Variants | for enums — when variants non-obvious |

## Activation

User says: "spec mode", "start spec", "spec on" → activate.
User says: "stop spec", "spec off" → deactivate, return to normal code writing.
