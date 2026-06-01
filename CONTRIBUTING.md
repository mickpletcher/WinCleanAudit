# Contributing

## Workflow

1. Create a branch for your change.
2. Keep changes focused and practical.
3. Run tests before opening a pull request.
4. Open a pull request with a clear summary.

## Pull Request Expectations

- Include test updates when behavior changes.
- Keep safety controls intact.
- Keep DryRun as the default.
- Keep NoPrompt blocked without Execute.

## Test Requirements

```powershell
Invoke-Pester -Path .\tests\Pester
```

## Safety Requirements For New Modules

- No destructive action in DryRun.
- Guard destructive actions behind Execute and confirmation.
- Use the common result contract.
- Handle access denied and locked files without crashing the run.

## Coding Style

- Use clear PowerShell naming.
- Prefer structured output over plain text.
- Keep module entry points explicit.
