# /tst - Run Tests

## Step 1: Identify Relevant Tests
Evaluate the current task, recent code changes, and available project commands to select the most appropriate test suite. Use repository knowledge to locate likely commands by:
- Inspecting Makefile targets, justfile recipes, package.json scripts, or common framework conventions
- Favoring smoke or unit tests when scope is narrow; escalate to broader suites only when necessary
- Asking for clarification before proceeding if the correct test target cannot be inferred confidently

## Step 2: Test-Fix Cycle
1. Execute the chosen test command
2. If tests fail:
   - Analyze failure causes and decide whether they stem from test gaps or implementation defects
   - Apply fixes methodically, updating tests or code as required
   - Re-run tests until they pass and the implementation is stable

Use TodoWrite to track progress through the fix cycle and communicate decisions clearly.

Please analyze the test results and provide fixes if needed. Use a systematic approach to resolve all test failures.
