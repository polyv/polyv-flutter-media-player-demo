---
description: 'Run Flutter tests and auto-fix until all pass'
---

# Run Tests

## Goal

Run all Flutter tests and automatically fix any failures until all tests pass.

## Steps

### Step 1: Run Plugin Tests

```bash
cd polyv_media_player && fvm flutter test
```

Capture the results. If tests fail, analyze the failures and fix them.

### Step 2: Run Example Tests

```bash
cd polyv_media_player && fvm flutter test example
```

Capture the results. If tests fail, analyze the failures and fix them.

### Step 3: Fix Failing Tests

For each failing test:

1. **Analyze the failure** - Read the error message and stack trace
2. **Identify the root cause** - Determine if it's a:
   - Test assertion issue (wrong expected value)
   - Code bug (implementation error)
   - Test setup issue (missing mock, incorrect fixture)
   - Flaky test (timing issue, dependency on external state)
3. **Fix the issue** - Apply the appropriate fix:
   - Update test assertions
   - Fix implementation bugs
   - Add/update mocks and fixtures
   - Make tests deterministic
4. **Re-run the test** - Verify the fix works

### Step 4: Repeat Until All Pass

Re-run both test suites until all tests pass.

## Quality Standards

- ✅ All tests must pass (no failures, no skips except with documented reason)
- ✅ Tests should be deterministic (same result every run)
- ✅ No hard-coded waits or sleeps
- ✅ Tests should be isolated (no shared state between tests)
- ✅ Follow Given-When-Then format
- ✅ Use appropriate test doubles (mocks, fakes, stubs)
