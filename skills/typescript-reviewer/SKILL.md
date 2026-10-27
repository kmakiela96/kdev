---
name: typescript-reviewer
description: "Strict functional-TypeScript code review of a PR or diff, plus a test-suite audit: missing scenarios and redundant tests (tests that only swap an input value but exercise the same branch). Read-only: reports findings, never edits code unless asked afterwards. Use only when the code under review is TypeScript and the request says so. Triggers: review this TypeScript PR, review this TS code, strict TypeScript review, functional TypeScript review, review TypeScript tests for redundancy. Do not trigger on a generic 'review this PR' without a TypeScript mention."
license: MIT
metadata:
  category: workflow
---

# typescript-reviewer: strict functional TypeScript PR review

Review as a very strict functional TypeScript developer. Be concrete and cite `file:line`. Leave out praise padding.

TypeScript supports ADTs (discriminated unions, branded types, non-empty tuples) and composition (`pipe`/`flow` from fp-ts). It lacks typeclasses and HKTs, erases types at runtime, and has escape hatches (`any`, `as`, `!`). Judge the code against what the language can express, and recommend fp-ts for `pipe`, `Option`, `Either` and `TaskEither`, and respect any other functional library the repo already uses.

## 1. Gather

- PR URL: `gh pr view <n> -R <owner/repo> --json title,body,files` and `gh pr diff <n> -R <owner/repo> > /tmp/prN.diff`. For github.twdcgrid.net, set `GH_HOST=github.twdcgrid.net`.
- Read the whole diff with the `read` tool (use offset/limit, never skip parts).
- Read the helpers the diff relies on but doesn't show: retry utilities, HTTP clients, error types, loggers, schema/validation modules, config wiring.
- Read `tsconfig.json` (is `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes` on?) and the lint config.
- List the directory tree around the changed files and read the imports of changed files, so module structure and dependency direction can be judged.
- Compare the PR description's claims against the code. Every mismatch is a finding.

## 2. Review checklist

### Correctness (highest priority)
- Illegal states that can be expressed: optional fields that must co-occur, `status: string` plus nullable payloads instead of a discriminated union, empty arrays where impossible.
- Unvalidated external data: `JSON.parse`, `res.json()`, `process.env`, request bodies cast with `as T` or typed `any`. Types are erased, so require a runtime validator (zod, io-ts, valibot) at every boundary.
- Success that hides failure: broad status mapping (any 404 counted as done), `catch {}` that swallows, `.catch(() => default)`.
- Unhandled or floating promises (`no-floating-promises`), `async` in `forEach`, missing `await` in `try`, `Promise.all` where one failure drops the rest (should it be `allSettled`?), unbounded concurrency.
- Retry policy: allowlist vs denylist, 429 and timeouts, non-idempotent calls retried, missing `AbortSignal`/timeouts on `fetch`.
- Per-item failure with global effect in loops and batches.
- Unsound narrowing: `as`, `as unknown as`, non-null `!`, user-defined type guards that don't check what they claim, `any` leaking through generics.
- Equality and truthiness traps: `==`, `if (x)` on `0`/`""`, `||` where `??` is meant, `Object.keys` ordering assumptions, mutating inputs (`sort`, `reverse`, `splice`).
- Dates and numbers: `Date` mutation and timezone use, floats for money.
- PII or secrets in error messages and logs (echoed bodies, `JSON.stringify(obj)`, `error.message` from downstream).

### Functional design
- Stringly typed code: `string` where a literal union, enum-like `as const` object, or branded type belongs (`type UserId = string & { readonly __brand: "UserId" }`); magic config keys.
- Unions without a discriminant, or `switch` over a union without an exhaustiveness check (`const _: never = x`; `assertNever`).
- Exceptions used as domain values: `throw` for expected failures, `catch (e)` treated as `Error` (it is `unknown`). Recommend fp-ts `Either` (or `TaskEither` for async) or a tagged error union; retryability should come from the type, not a boolean flag.
- Arrays where emptiness is impossible: `[T, ...T[]]` or a `NonEmptyArray`; `arr[0]` without `noUncheckedIndexedAccess` handling.
- Mutation: `let`, `push`, in-place `sort`, mutated parameters, missing `readonly` / `ReadonlyArray` / `Readonly<T>` on inputs and models; `for` loops with accumulators where `map`/`filter`/`reduce` or a fold reads better.
- Optional-chaining pyramids or `null`/`undefined` mixed: pick one absence representation, recommending fp-ts `Option` or a single `| undefined`.
- Validation written as manual flag/array bookkeeping: prefer a schema, or an applicative/accumulating validation.
- Side effects belong at the edges of the application (entry points, handlers, adapters); core logic should be pure. Flag I/O, mutation, time, randomness, or logging inside domain functions, in expressions, at module top level, or in class constructors; work recomputed per call that belongs at construction. Dependencies imported directly instead of passed in (hard to fake).
- Composition: deeply nested calls or temp variables where fp-ts `pipe`/`flow` would help; recommend adopting fp-ts (`pipe`, `Option`, `Either`, `TaskEither`) when the repo has none, but follow the repo's existing library if it uses another; point-free tricks that hurt readability are not wins.
- Classes with mutable state and inheritance where plain functions plus data would do; `enum` (prefer literal unions / `as const`); `interface` vs `type` inconsistency; barrel files causing cycles.
- Type-level overreach: conditional types nobody can read, `Partial<>` used to dodge modelling, wide `Record<string, X>` where a union of keys fits.
- Layering: business rules (dedup, policy) in wire or infra code; domain models that copy the wire format with every field optional (YAGNI).
- Logging: one failure logged several times, wrong level, lost context.
- Domain primitives: `string`/`number` for ids, emails, money and similar should be branded types (`string & { readonly __brand: "UserId" }`, or zod `.brand()`). Require one validating constructor returning `Either`/`Result`; flag `as UserId` anywhere outside it, and brands built from unvalidated external data. Make sure ids of different entities can't be swapped.
- Inheritance: flag `extends` of concrete classes and `instanceof` chains. Model closed variants as discriminated unions with exhaustive `switch`; keep inheritance only for a real open extension point.
- Composition: flag behaviour inherited for reuse that could be a function or a dependency passed in; flag hidden dependencies (module-level singletons, imported clients, `process.env` read inside logic) instead of parameters.
- Lint escapes: `// @ts-ignore` (should be `@ts-expect-error` with reason), `eslint-disable` without justification.

### Structure (only when the diff adds files, or you are explicitly asked to review structure)
- Organization axis: do modules group code by the domain concept or capability they serve, or by a generic technical role? If one change must touch many sibling modules that share no domain meaning, the concept is scattered. Judge against the structure the repo already uses; flag inconsistency or scatter, not a particular naming scheme.
- Dependency direction: identify which code is core (domain rules) and which is edge (I/O, wire formats, frameworks, config). Core must not import from edge. Name the offending import in the finding.
- Smells, whatever the names: import cycles (barrel `index.ts` re-exports are a common cause); catch-all modules everything depends on (`utils`, `common`, `shared`, `misc`); a new file in a layer that doesn't match its responsibility; public surface wider than needed (unexport internals; consider `import/no-cycle` or `eslint-plugin-boundaries`).

## 3. Test audit

### Redundancy: be aggressive
A test is redundant when it changes only the input value (another string, status code, or field) but runs the same branch and asserts the same thing. Look for:
- `it.each` / `test.each` / `forEach` tables whose rows all hit one branch. Keep one representative, or make a single table that covers *every* partition.
- Mirror-image tests (A-with-B vs B-with-A) that hit the same code.
- Asserts implied by earlier asserts (`toHaveLength(1)` right after `toEqual([x])`).
- The same behaviour checked at several layers (unit, integration, e2e) with no new risk covered.
- Snapshot tests (`toMatchSnapshot`) of output that another test already pins; large snapshots that hide intent.
- Type-only behaviour re-tested at runtime that the compiler already guarantees.

### Wrong or misleading tests
- Test names that contradict their assertions.
- Tautological tests: assertions against mocks configured in the test itself, or over-mocked modules so no production code runs.
- Missing `await` / `return` / `expect.assertions(n)` so async assertions never run; `expect(promise).rejects` not awaited.
- Flaky timing: real timers, `setTimeout` sleeps, `Date.now()` without fake timers, order-dependent tests, shared mutable state between tests, missing mock reset.
- `as any` / `as unknown as` in tests that hides a wrong shape.

### Missing scenarios
For each finding in sections 2 and 3, check whether a test would catch it. List missing scenarios such as:
- malformed or unexpected external data failing the validator
- boundary, empty, and unknown-variant inputs (the `never` branch)
- every status class, transport errors, timeouts, aborts
- rejected promises and partial failure in `Promise.all`
- PII in a structured error body
- wiring with missing env/config
- duplicates where the first copy is the bad one
- brand constructors rejecting invalid values (empty, out-of-range, malformed)

## 4. Output format

1. **Correctness risks (must fix)**: numbered, each with its impact and a suggested fix.
2. **Functional design**: bullets.
3. **Tests**: a *Redundant* table (file | tests | why), a *Wrong/misleading* list, and a *Missing scenarios* list.
4. **Verdict**: request changes or approve, naming the blockers.

Don't change code during the review. If the user then asks for fixes, apply them, then run `tsc --noEmit`, the linter, the formatter and the affected tests.
