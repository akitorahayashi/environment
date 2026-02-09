# Testing

- Run via `just test` (runs both unit-test and intg-test)
- `just unit-test`: Unit tests only (fast, mocks, no external processes)
- `just intg-test`: Integration tests only (subprocess, real scripts)
- Mocks must be Protocol-compliant for type safety
- Prefer DI over monkeypatch where possible
