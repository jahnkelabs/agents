---
description: Contract-first tests through production entry points; refactor-resistant
---

# Testing philosophy

Automated tests should exercise code **the way it is used outside the test environment**—through the same public entry points, protocols, and dependency resolution paths as production. This is contract-first testing: not necessarily full E2E, but never a test-only invocation path that production never takes.

## Rule of thumb

**A test is useful when the internals behind the contract under test can be entirely refactored without requiring the test to be modified.**

If a test breaks while behavior at the contract boundary is unchanged, it was asserting on internals or using a test-only invocation path—fix the test, not the production code. Contract changes (new flag, response field, status code, event payload) legitimately require test updates.

## Default policy

- **Default:** Invoke the system through the path production uses—shell, HTTP, queue, event bus, import, RPC—and assert on what a caller can observe there: outputs, exit codes, status codes, side effects visible at the boundary. Not private state.
- **Dependencies:** Resolve them the way the framework does—container, DI, env config—rather than hand-building a graph that hides a missing binding.
- **Goal:** Refactor-resistant tests that catch wiring and container regressions, not brittle tests coupled to internals.
- **Exceptions:** Only use direct internal invocation when the user explicitly asks, or for pure logic with no integration surface—and even then, test via the public API when one exists.

## Worked example: a Laravel listener

In production the framework dispatches the event and resolves the listener from the container, so the test does the same.

**Prefer:** `Event::fake()` / `Event::assertDispatched` flows, or dispatch the event and assert the side effects; feature tests that exercise the full pipeline.

**Avoid:** `new MyListener($mockA, $mockB)->handle($event)`—passes while container bindings or constructor signatures drift in production.

The same substitution applies everywhere. A CLI test runs the built binary through argv rather than calling `run()` with mocked `os.Args`. An HTTP test issues a real request through routing, middleware, and serialization rather than instantiating a controller and calling an action method. Jobs, subscribers, and console commands go through the framework entry point.

## Anti-patterns

| Anti-pattern | Why it fails |
|--------------|--------------|
| Direct `handle()` / internal method with hand-built deps | Production uses container/framework wiring |
| Testing private methods | Violates refactor rule—internals change, test breaks, behavior may not |
| Over-mocking collaborators production never mocks | Masks integration and configuration errors |
| Asserting call order on internal collaborators | Couples tests to implementation, not contract |
