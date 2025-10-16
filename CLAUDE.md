## Test Writing Guidelines
- When writing test code, ensure it's easy to debug and avoid excessive nesting to prevent difficulties in tracing errors.
- When running test code, focus on executing only user-specified or change-related test cases to avoid running excessive tests. If an error occurs, run tests individually to narrow down the scope and pinpoint the root cause.
- If an error is found while running test cases, exit immediately to debug and focus on resolving the first encountered issue, ignoring subsequent test cases for now.

## Security Guidelines
- When handling keys or credentials, do not display or transmit them over the network; load them locally into the program instead.

## Git Best Practices
- When committing code, avoid using git add .. Only submit the necessary modified files, excluding unrelated configuration files or other unchanged files.