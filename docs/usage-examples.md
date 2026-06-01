# Usage Examples

## DryRun

```powershell
.\src\WinCleanAudit.ps1 -DryRun
```

## Execute With Confirmation

```powershell
.\src\WinCleanAudit.ps1 -Execute
```

## Execute With NoPrompt

```powershell
.\src\WinCleanAudit.ps1 -Execute -NoPrompt
```

## Report Path Override

```powershell
.\src\WinCleanAudit.ps1 -DryRun -ReportPath .\reports
```

## Module Notes

- Temp cleanup audits approved temp folders in DryRun.
- Windows Update cache cleanup only removes child items in the download folder.
- Recycle bin cleanup only runs in Execute mode.
- Old log cleanup targets safe system locations and age threshold.
- Browser cache cleanup targets cache files only and skips profile data.
- Startup inventory is audit only.
- Large file report is audit only and defaults to 500 MB threshold.
- Duplicate downloads report is audit only.
- Installed apps inventory is audit only.
- Disk health report is read only.
