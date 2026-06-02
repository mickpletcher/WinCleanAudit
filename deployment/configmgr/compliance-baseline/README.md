# ConfigMgr Compliance Baseline

These scripts are examples for a ConfigMgr configuration baseline that verifies
recurring WinCleanAudit audit status.

## Detection

Use `detection.ps1` as the compliance discovery script.

Expected compliant output:

```text
Compliant
```

Noncompliant output includes comma separated reasons:

```text
NonCompliant:ScheduledTaskMissing,RecentReportMissing
```

The detection script checks:

- WinCleanAudit script presence.
- WinCleanAudit config presence.
- Scheduled task registration.
- Recent JSON report generation.

## Remediation

Use `remediation.ps1` only when you want ConfigMgr to repair recurring audit
status.

The remediation script:

- Re-registers the scheduled DryRun task.
- Runs a DryRun with `-NoBrowserLaunch`.
- Generates JSON and CSV reports.

Validate on a pilot collection before enabling remediation broadly.
