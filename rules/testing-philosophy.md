---
description: Contract-first tests through production entry points; refactor-resistant
---

# Testing philosophy

An automated test must exercise code **the way it is used outside the test environment**. Use the same public entry points, protocols, and dependency resolution paths as production. This is contract-first testing. It does not require full E2E. It never uses a test-only invocation path, because production never takes that path.

## Rule of thumb

**A test is useful when you can refactor everything behind its contract without changing the test.**

When a test breaks and the contract boundary did not change, the test is at fault. It asserts on internals, or it uses a test-only invocation path. Fix the test, not the production code. A contract change legitimately requires a test update: a new flag, a response field, a status code, an event payload.

## Default policy

- **Default:** Invoke the system through the path production uses: shell, HTTP, queue, event bus, import, or RPC. Assert on what a caller can observe there: outputs, exit codes, status codes, and side effects at the boundary. Never assert on private state.
- **Dependencies:** Resolve them the way the framework does: container, DI, or env config. A hand-built graph hides a missing binding.
- **Goal:** Refactor-resistant tests that catch wiring and container regressions, not brittle tests coupled to internals.
- **Exceptions:** Use direct internal invocation only when the user asks for it, or for pure logic with no integration surface. Even then, test through the public API when one exists.

## Worked example: a Laravel listener

In production the framework dispatches the event and resolves the listener from the container, so the test does the same.

**Prefer:** `Event::fake()` / `Event::assertDispatched` flows, or dispatch the event and assert the side effects; feature tests that exercise the full pipeline.

**Avoid:** `new MyListener($mockA, $mockB)->handle($event)`—it passes while container bindings or constructor signatures change in production.

The same substitution applies everywhere. A CLI test runs the built binary through argv rather than calling `run()` with mocked `os.Args`. An HTTP test issues a real request through routing, middleware, and serialization. It does not instantiate a controller and call an action method. Jobs, subscribers, and console commands go through the framework entry point.

## Anti-patterns

| Anti-pattern | Why it fails |
|--------------|--------------|
| Direct `handle()` or an internal method with hand-built dependencies | Production uses container and framework wiring |
| Testing private methods | The refactor rule fails: internals change and the test breaks, but the behavior did not change |
| Over-mocking collaborators production never mocks | Hides integration and configuration errors |
| Asserting call order on internal collaborators | Couples tests to implementation, not contract |
