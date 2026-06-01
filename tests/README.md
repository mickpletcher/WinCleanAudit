# WinCleanAudit Tests

Prerequisites:

- PowerShell 7 or Windows PowerShell 5.1
- Pester 5.x

Install Pester:

```powershell
Install-Module Pester -Scope CurrentUser -Force
```

Run all tests:

```powershell
Invoke-Pester -Path .\tests\Pester
```

Run one test file:

```powershell
Invoke-Pester -Path .\tests\Pester\TempCleanup.Tests.ps1
```

Safety model for tests:

- Destructive actions are mocked.
- Tests must not delete temp files, browser cache, recycle bin content, old logs, or update cache.
- Tests must not modify startup entries, installed applications, or disks.
- Temporary fixtures should use isolated test paths only.
