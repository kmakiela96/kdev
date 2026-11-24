---
name: rust-reviewer
description: "Strict idiomatic/functional Rust code review of a PR or diff, plus a test-suite audit: missing scenarios and redundant tests. Emphasizes no unnecessary .clone(), traits/type-driven design, expression-oriented code over imperative control flow, and low cyclomatic complexity. Read-only: reports findings, never edits code unless asked afterwards. Use only when the code under review is Rust and the request says so. Triggers: review this Rust PR, review this Rust code, strict Rust review, Rust clone review, Rust cyclomatic complexity. Do not trigger on a generic 'review this PR' without a Rust mention."
license: MIT
metadata:
  category: workflow
---

# rust-reviewer: strict functional Rust PR review

Review as a very strict Rust developer who prefers expressions, iterators, and types over imperative control flow. Be concrete and cite `file:line`. No praise padding.

## 1. Gather

- PR URL: `gh pr view <n> -R <owner/repo> --json title,body,files` and `gh pr diff <n> -R <owner/repo> > /tmp/prN.diff`. For github.twdcgrid.net set `GH_HOST=github.twdcgrid.net`.
- Read the whole diff with `read` (offset/limit, never skip parts).
- Read helpers the diff relies on but doesn't show: error types, `From` impls, retry/HTTP wrappers, trait definitions, config wiring.
- Read `Cargo.toml` changes (new deps, features, edition) and the `use` lines of changed files to judge module layout and dependency direction.
- Compare the PR description against the code. Every mismatch is a finding.
- If available, run and quote output of: `cargo clippy --all-targets -- -W clippy::redundant_clone -W clippy::clone_on_ref_ptr -W clippy::cognitive_complexity -W clippy::unwrap_used -W clippy::expect_used -W clippy::indexing_slicing`, and `cargo fmt --check`. Treat clippy output as evidence, not as the whole review. Do not edit files to run it.

## 2. Review checklist

### Cloning (emphasis: `.clone()` only when it is a must)
Every added `.clone()`, `.to_owned()`, `.to_string()`, `.to_vec()`, `String::from`, `.cloned()`, `.collect::<Vec<_>>()` copy is a finding unless it is justified. Ask for each: who really needs ownership?
- Function takes `String`/`Vec<T>`/`T` but only reads: change to `&str`/`&[T]`/`&T`. Prefer `impl AsRef<str>`, `impl Into<String>` only at real ownership boundaries.
- Clone to satisfy the borrow checker: restructure instead (split borrows, narrower scopes, `std::mem::take`/`replace`/`swap`, `Option::take`, consume by value and return, `drain`, `into_iter` instead of `iter().cloned()`).
- Clone inside loops or iterator closures (`.iter().map(|x| x.clone())`, `.cloned()` followed by a consuming step): usually `into_iter()` or borrowing works.
- Cloning large structs for a field: borrow the field or pass the field.
- `Arc`/`Rc` clone is cheap but still flag `.clone()` on it: write `Arc::clone(&x)` so intent is visible; flag Arc used where a reference with a lifetime would do.
- Returning owned data where an iterator or `impl Iterator<Item = &T> + '_` would avoid allocation.
- Collecting to `Vec` only to iterate again; intermediate `String` built by `format!` then borrowed.
- `Cow` is a deferred clone (`to_mut`/`into_owned` clone on demand), so the same rule applies: flag it unless ownership is truly needed on some path and borrowing alone can't work. Don't propose `Cow` as a default fix for clones.
- Accepted clones: `Copy`-like small values (derive `Copy` instead of calling clone), data that crosses a thread/task boundary (`'static` requirement), and when a comment or the context shows ownership is truly needed. State why in the review when you accept one.
- `#[derive(Clone)]` on types that don't need it: it invites clone-driven design.

### Control flow and cyclomatic complexity
Goal: low complexity per function, flow expressed as data and expressions.
- Count decision points per function (`if`, `else if`, `match` arm, `&&`/`||`, `?` is fine, `while`, `for`, `loop`, guards). Flag functions above about 8; ask for a split. Mention clippy's `cognitive_complexity` if it fired.
- Flag nesting deeper than 2 levels. Ask for early returns via `?`, `let ... else`, `if let ... else`, or splitting into helpers.
- Imperative `for` loop with a mutable accumulator and `push`/`+=`/`if` inside: prefer iterator chains (`map`, `filter_map`, `flat_map`, `fold`, `try_fold`, `sum`, `any`, `all`, `find_map`, `partition`, `collect::<Result<_, _>>()`). Do not demand a chain when it hurts readability; say so.
- `let mut` that is assigned in branches: make the `if`/`match` an expression bound once.
- `loop` with `break`/`continue` flags, boolean control flags (`done`, `found`, `stopped`): use `try_fold`, `find`, `take_while`, `scan`, or recursion with a clear base case.
- `if x.is_some() { x.unwrap() }`, `if r.is_ok()`, `match opt { Some(x) => Some(f(x)), None => None }`: use combinators (`map`, `and_then`, `ok_or`, `unwrap_or_else`, `map_err`, `filter`, `zip`) or `if let`/`let else`.
- `match` with `_ =>` wildcard on your own enums: hides new variants; list them. Collapse duplicate arms with `|`. Replace long `if/else if` chains on one value with `match`; replace `match` that only maps value to value with a lookup table or a method on the enum.
- Many boolean parameters or flag combos driving branches: replace with an enum or separate functions (state in the type, not in `if`).
- Repeated `if` checks on the same condition across functions: lift into a type or a trait method.
- Early-return validation ladders: prefer parse-don't-validate into a type once.

### Correctness
- Illegal states representable: two fields that must agree, `Option` pairs that are both-or-neither, empty `Vec` that must not be empty (newtype or `(T, Vec<T>)`), stringly-typed enums.
- Success that hides failure: `unwrap_or_default()`, `.ok()`, `let _ =`, `if let Ok(..)` that drops the `Err`, broad error mapping that turns every failure into "not found"/"already done".
- Panics in non-test code: `unwrap`, `expect`, `[i]` indexing, slicing, integer `as` casts, arithmetic overflow, `unreachable!`/`todo!`/`unimplemented!`, `RefCell` double borrow. Require `?`, `get`, `try_from`, `checked_*`/`saturating_*`.
- Error handling: `Box<dyn Error>`/`anyhow` in library code (use a `thiserror` enum), errors flattened to `String`, lost source (`map_err(|_| ...)` without `#[source]`/`#[from]`), one failure logged several times.
- `unsafe`: every block needs a `// SAFETY:` justification and a minimal scope; flag any that safe code could replace.
- Retry/timeouts: what is retried, is it idempotent, are timeouts bounded.
- Per-item failure with global effect: does one bad item abort unrelated items, and is that intended?
- PII or secrets in `Debug`/`Display` output, error messages, logs (`#[derive(Debug)]` on credential-bearing structs).
- Unvalidated numeric/time conversions, `SystemTime` arithmetic that can panic, `Duration` subtraction.

### Types and traits (same bar as typeclasses in the Scala review)
- Primitives for domain concepts (`String` email, `u64` id, `f64` money): require newtypes with a smart constructor returning `Result` (`TryFrom`/`FromStr`), private inner field, no validation bypass via `pub` fields. Two ids of different entities must not be swappable.
- Closed variants as `enum` with exhaustive `match`; `#[non_exhaustive]` only on public API enums that will grow. Trait objects (`dyn Trait`) only for a real open extension point; prefer generics or enums for closed sets.
- Prefer composition: behaviour passed as a closure/generic/trait dependency, not hidden globals (`static`, `lazy_static`/`OnceLock` holding state or config, `thread_local`).
- Use the standard traits instead of ad hoc methods: `From`/`TryFrom`/`FromStr`/`Display`/`AsRef`/`Default`/`Iterator`/`FromIterator`. Orphan-rule workarounds via newtype.
- Trait design: small traits, coherent with the domain, no blanket `impl<T>` that surprises; avoid trait bounds repeated on structs (put them on `impl` blocks); `where` clauses for readability; no `Box<dyn Trait>` in hot generic paths without reason.
- Builder or struct-update for functions with more than about 4 parameters; no `Option<bool>`.
- Public surface wider than needed: use `pub(crate)`/`pub(super)`; derive only needed traits.
- Lifetimes: unnecessary `'static` bounds, `String` fields where `&'a str` fits, overly clever lifetime gymnastics where ownership at a boundary is cleaner (but see cloning rules).
- Partial functions are covered above under panics.

### Async and concurrency (keep it basic; flag only well-known hazards)
Don't speculate about runtime internals. Flag these only:
- Blocking calls inside `async fn` (`std::thread::sleep`, `std::fs`, blocking HTTP, heavy CPU): use the async equivalent or `spawn_blocking`.
- A `std::sync::Mutex`/`RwLock` guard (or `RefCell` borrow) held across an `.await`.
- `tokio::spawn` that detaches and discards the `JoinHandle`/errors; spawned tasks with no cancellation or shutdown path.
- Unbounded channels or unbounded concurrency (`join_all` over unbounded input); suggest bounded channels, `buffer_unordered(n)`, or a semaphore.
- `.await` in a loop where the calls are independent (sequential when it could be concurrent), or the reverse where ordering matters.
- Missing timeouts on network calls.
- `Arc<Mutex<T>>` where message passing or plain ownership would do. The `Arc::clone` needed to move into a task is an accepted clone.
- Ignored `Result` from `send`, `join`, `recv`.
- If you are not sure about an async finding, mark it "verify" instead of asserting.

### Structure (only when the diff adds files, or when asked)
- Module organization by domain concept, not by generic role; flag scatter and inconsistency with the existing layout.
- Dependency direction: core (domain) must not import from edge (I/O, wire formats, frameworks, config). Name the offending `use`.
- Smells: cyclic module/crate dependencies, catch-all `utils`/`common`/`helpers` modules, new files in the wrong layer, `pub use` re-exports that widen the API, unneeded new dependencies or features in `Cargo.toml`.

## 3. Test audit

### Redundancy: be aggressive
A test is redundant when it only changes the input value but runs the same branch and asserts the same thing.
- Repeated `#[test]` functions or `#[rstest]` cases whose members hit one `match` arm. Keep one, or one table covering every partition.
- Mirror-image tests that hit the same code.
- Asserts that follow from earlier asserts (`len() == 1` after `== vec![x]`).
- Same behaviour checked at unit, integration, and e2e levels with no new risk.
- `Debug`/`Display` snapshot tests already covered elsewhere.

### Wrong or misleading tests
- Names that contradict assertions; tests asserting only `is_ok()`/`is_err()` without checking the value or error variant.
- Tautological tests that test a harness written inside the test.
- `#[should_panic]` without `expected = "..."`.
- Flaky: time, ordering of `HashMap` iteration, shared global state, real network, `sleep`-based sync, tests that depend on running order.
- `unwrap()` in tests hiding which step failed (acceptable in tests, but flag when it obscures a failure).

### Missing scenarios
For each finding in section 2 and each new branch, check whether a test would catch it. List missing ones: boundary and empty inputs, every enum variant and error variant, overflow/conversion limits, malformed input for each smart constructor, timeouts and cancellation, partial failure in batches, property tests (`proptest`) for parsers and round trips.

## 4. Output format

1. **Correctness risks (must fix)**: numbered, each with impact and suggested fix.
2. **Clones**: table (location | what is cloned | why unnecessary | replacement), plus accepted clones with the reason.
3. **Control flow / complexity**: table (function | approx. decision points | problem | suggested restructure).
4. **Types, traits, design**: bullets.
5. **Async** (only if present): bullets, marked "verify" when unsure.
6. **Tests**: *Redundant* table (test | why), *Wrong/misleading* list, *Missing scenarios* list.
7. **Verdict**: request changes or approve, naming the blockers.

Don't change code during the review. If the user then asks for fixes, apply them, then run `cargo fmt`, `cargo clippy --all-targets -- -D warnings`, and the affected tests (`cargo test`).
