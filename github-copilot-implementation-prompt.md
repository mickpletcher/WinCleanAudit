# GitHub Copilot Implementation Prompt

Use this prompt in GitHub Copilot Chat from the root of this repository.

```text
You are working in this repository:

C:\Users\mick0\OneDrive\Documents\Code & Dev\GitHub\windows-system-cleanup-tool

Your task is to create the WinCleanAudit PowerShell project by executing the implementation prompts in the prompts folder, in numeric order.

Read and implement these files sequentially:

1. prompts/01-CreateWindowsCleanupTool.md
2. prompts/02-Build-Core-Framework.md
3. prompts/03-Implement-Temp-Cleanup.md
4. prompts/04-Implement-Windows-Update-Cache.md
5. prompts/05-Implement-Recycle-Bin-Cleanup.md
6. prompts/06-Implement-Old-Log-Cleanup.md
7. prompts/07-Implement-Browser-Cache-Cleanup.md
8. prompts/08-Implement-Startup-Inventory.md
9. prompts/09-Implement-Large-File-Report.md
10. prompts/10-Implement-Duplicate-Downloads.md
11. prompts/11-Implement-Installed-Apps-Inventory.md
12. prompts/12-Implement-Disk-Health-Report.md
13. prompts/13-Implement-Reporting-Engine.md
14. prompts/14-Add-Pester-Tests.md
15. prompts/15-Add-GitHub-Actions.md
16. prompts/16-Write-Documentation.md
17. prompts/17-Prepare-Release-v1.md

Important execution rules:

* Implement one prompt at a time.
* Do not skip prompts.
* After each prompt, verify the acceptance criteria in that prompt before moving to the next prompt.
* Prefer editing existing files over creating unrelated new files.
* Keep the implementation simple and practical.
* Use PowerShell-native patterns.
* Do not add backwards-compatibility shims for replaced implementation details.
* Do not perform real destructive cleanup while implementing or testing.
* Do not run the tool with -Execute.
* Do not run the tool with -NoPrompt.
* Use DryRun only during validation.
* Mock destructive behavior in Pester tests.
* Do not empty the Recycle Bin.
* Do not delete browser cache.
* Do not delete temp files.
* Do not delete old logs.
* Do not stop real Windows Update services during tests.
* Do not modify startup entries.
* Do not uninstall applications.
* Do not repair, format, optimize, defrag, resize, or modify disks.

Project safety rules:

* Default to DryRun.
* Never delete anything unless -Execute is explicitly used.
* Require confirmation before destructive actions unless -Execute -NoPrompt is used.
* Block -NoPrompt unless -Execute is also used.
* Never delete from Desktop, Documents, Pictures, Videos, Music, OneDrive, Dropbox, Google Drive, Git repositories, or source-code folders.
* Handle access-denied errors cleanly.
* Continue running if one module fails.
* Return structured PowerShell objects.
* Generate report-ready output.
* Avoid destructive tests unless fully mocked.

Architecture rules:

* Use configuration, module loading, and the pipeline to run modules.
* Do not hard-code per-module calls in src/WinCleanAudit.ps1.
* Keep module entry points aligned with their prompt files.
* Use the common result contract from prompts/02-Build-Core-Framework.md.
* Use the reporting API standardized in prompts/02 and prompts/13:
  * New-WinCleanReport
  * ConvertTo-ReadableSize
  * Add-ReportSection
  * Write-MarkdownReport

Common result contract:

[PSCustomObject]@{
    TaskName        = ""
    Module          = ""
    Status          = "Success|Warning|Error|Skipped"
    Mode            = "DryRun|Execute"
    ItemsScanned    = 0
    ItemsModified   = 0
    EstimatedBytes  = 0
    RecoveredBytes  = 0
    ActionsTaken    = @()
    Warnings        = @()
    Errors          = @()
    Recommendations = @()
    Details         = @()
    Duration        = 0
}

Validation after each prompt:

* Check PowerShell syntax for changed .ps1 and .psm1 files.
* Run relevant Pester tests if they exist.
* If tests cannot run, document why in the response.
* Confirm the implementation still defaults to DryRun.
* Confirm -NoPrompt without -Execute is rejected.
* Confirm no destructive cleanup is performed by validation.

Repository documentation rules:

* Keep changelog.md updated with every repo change.
* Keep assessment.md updated with the current repo overview, implementation status, known risks, and next steps.
* The generated WinCleanAudit project may also contain its own CHANGELOG.md. Keep that separate from the root-level changelog.md that tracks this prompt repository.

Final output:

When all prompts are implemented, provide:

* Summary of files created or changed.
* Tests run and results.
* Any tests skipped and why.
* Remaining risks or manual checks.
* Confirmation that no destructive cleanup was run.
```
