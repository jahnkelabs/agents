---
description: Contract-first tests through production entry points; refactor-resistant
---


# Testing philosophy

Automated tests should exercise code **the way it is used outside the test environment**—through the same public entry points, protocols, and dependency resolution paths as production. This is contract-first testing: not necessarily full E2E, but never a test-only invocation path that production never takes.

## Rule of thumb

**A test is useful when the internals behind the contract under test can be entirely refactored without requiring the test to be modified.**

If you refactor implementation but preserve behavior at the contract boundary (CLI output, HTTP response, dispatched side effects), the test should still pass. If it fails, the test is probably asserting on internals or using a non-production invocation path—rewrite the test, not the production code.

Contract changes (new flag, field, status code, event payload) legitimately require test updates.

## Default policy

- **Default:** Prefer tests that call the system's **public contract** (CLI argv, HTTP request/response, published events, job dispatch, module exports).
- **Goal:** Refactor-resistant tests that catch wiring/container regressions, not brittle tests coupled to internals.
- **Exceptions:** Only use direct internal invocation when the user explicitly asks, or for pure logic with no integration surface—and even then, test via public API when one exists.

## Decision checklist

Before writing or approving a test, ask:

1. **How does production invoke this code?** (shell, HTTP, queue, event bus, import, RPC, etc.)
2. **Does this test use that same path?** If not, rewrite or justify.
3. **Could I refactor all internals without touching this test?** If no, narrow assertions to the contract boundary or change how the test invokes the system.
4. **Are dependencies resolved the same way?** Framework container, DI, env config—not hand-built graphs that hide missing bindings.
5. **What observable outcome matters to callers?** Assert on outputs, exit codes, status codes, side effects visible at the boundary—not private state.

## Examples

### CLI tools

Run commands the way an end user would: subprocess or test harness invoking `bin/<tool> …` (or packaged equivalent), not calling internal `run()` with mocked `os.Args` unless that path is what production uses.

**Prefer:** `exec` / `go test` integration calling the built binary; Cobra/Click test helpers that parse argv and run the root command.

**Avoid:** Importing unexported packages and calling orchestration functions directly while skipping flag parsing, config loading, and exit-code handling.

### HTTP APIs

Call endpoints the way a consumer would: real HTTP against the running app (in-process test server is fine), with auth, headers, and serialization as clients use them.

**Prefer:** `httptest` / Pact / supertest-style requests to routes; contract tests on request/response schema.

**Avoid:** Instantiating controllers or handlers in tests and calling action methods with manually injected dependencies that bypass middleware, routing, and container resolution.

### Laravel listeners (and similar framework hooks)

Do not call `$listener->handle($event, …)` with manually constructed dependencies. In production the framework dispatches the event and resolves the listener from the container.

**Prefer:** `Event::fake()` / `Event::assertDispatched` flows, or dispatch the event and assert side effects; feature tests that exercise the full pipeline.

**Avoid:** `new MyListener($mockA, $mockB)->handle($event)` — can pass while container bindings or constructor signatures drift in production.

Apply the same rule to jobs, subscribers, middleware, and console commands: **dispatch or invoke through the framework entry point.**

## Anti-patterns

| Anti-pattern | Why it fails |
|--------------|--------------|
| Direct `handle()` / internal method with hand-built deps | Production uses container/framework wiring |
| Testing private methods | Violates refactor rule—internals change, test breaks, behavior may not |
| Over-mocking collaborators production never mocks | Masks integration and configuration errors |
| Asserting call order on internal collaborators | Couples tests to implementation, not contract |

## Refactors and test changes

When refactoring production code, **update tests only when the public contract changes** (new flag, response field, event payload). If tests break but behavior at the boundary is unchanged, apply the rule of thumb: the test was coupled to internals or a test-only path—fix the test (invocation path and assertions), do not “fix” production to satisfy brittle tests.
