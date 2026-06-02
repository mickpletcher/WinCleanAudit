# Repository Assessment

## Quick Overview

This repository now contains the generated `WinCleanAudit`
PowerShell project plus the prompt set used to create it.

`WinCleanAudit` is a safety-first Windows cleanup and audit toolkit.
The core app, modules, tests, docs, workflows, and prompt files are present.

## Current Repo Contents

```text
.
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
├── docs/
│   ├── project-spec.md
│   ├── roadmap.md
│   ├── safety-rules.md
│   └── usage-examples.md
├── prompts/
├── reports/
├── src/
│   ├── WinCleanAudit.ps1
│   └── modules/
├── tasks/
├── tests/Pester/
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── LICENSE
├── assessment.md
├── changelog.md
├── completed-upgrades.md
└── github-copilot-implementation-prompt.md
```

`future-upgrades.md` exists locally and is intentionally ignored by git.

When an item from `future-upgrades.md` is implemented, update:

* `future-upgrades.md`
* `completed-upgrades.md`
* `changelog.md`
* `assessment.md`

## Current Status

Implementation status: generated and smoke-tested.

Validation performed on June 1, 2026:

* PowerShell syntax check passed for all `.ps1` and `.psm1` files.
* `.\src\WinCleanAudit.ps1 -DryRun` completed successfully.
* Pester test suite passed: 39 passed, 0 failed.
* Markdownlint passed: 12 files checked, 0 errors.
* DryRun generated Markdown, HTML, and log files under `reports/`.
* `README.md` was rewritten for novice users with safer first-run guidance.
* Pipeline dispatch was refactored to use configured module entry points.
* PowerShell test workflow was cleaned up.
* README badge URLs were updated to the real GitHub repository path.
* GitHub Actions workflow pins were updated to Node 24-compatible
  action versions.
* Markdown prose was wrapped and `.markdownlint.json` was added for MD013.
* Markdown lint workflow excludes local prompt and report content.
* Lightweight GitHub project governance was added through
  `docs/project-spec.md`, issue templates, and a pull request template.

## Git Status Notes

Most project files are currently untracked because the repo originally tracked
only:

```text
.gitignore
LICENSE
prompts/01-CreateWindowsCleanupTool.md
```

The `.gitignore` was updated so:

* `future-upgrades.md` remains local-only.
* `prompts/` is ignored and should remain local-only.
* generated `reports/*.md`, `reports/*.html`, and `reports/*.log` are
  ignored.
* `reports/.gitkeep` can be tracked.
* `testResults.xml` from Pester CI runs is ignored.

Before committing, review `git status` and intentionally stage the generated
project files, docs, workflows, and repo tracking files.

Do not stage `prompts/`.

## Safety Model

The app enforces these project rules:

* Default mode is `DryRun`.
* Cleanup requires explicit `-Execute`.
* `-NoPrompt` is rejected unless `-Execute` is also supplied.
* Protected folders are excluded.
* Module failures should not stop the full run.
* Modules return structured PowerShell objects.
* Reports are generated in Markdown.
* DryRun also generates an HTML report and opens it in the default browser.

## Standard Result Contract

Modules should return this shape:

```powershell
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
```

## Reporting API

The reporting module uses:

```powershell
New-WinCleanReport
ConvertTo-ReadableSize
Add-ReportSection
Write-MarkdownReport
Write-HtmlReport
```

## Findings

### 1. Pipeline dispatch is now configuration-driven

`src/modules/Pipeline.psm1` now resolves module entry points from
`tasks/windows-cleanup.yaml`.

This removes the previous hard-coded module map from the pipeline.

Priority: handled.

### 2. GitHub Actions PowerShell workflow was cleaned up

The unnecessary `actions/setup-python@v5` step was removed from
`.github/workflows/powershell-tests.yml`.

Windows runners already include PowerShell.

Priority: handled.

### 3. README badges now use the real repository path

`README.md` badges now point to:

```text
https://github.com/mickpletcher/windows-system-cleanup-tool/actions/...
```

Priority: handled.

### 4. Tests pass but are still mostly contract-level

The Pester suite validates imports, DryRun behavior, basic output shape,
and guards.

It does not deeply test edge cases for every destructive path, locked files,
registry view behavior, browser profile exclusions, service restart failure,
or large directory performance.

Priority: medium before relying on `-Execute`.

### 5. Generated reports should stay out of source control

DryRun creates report and log files under `reports/`.

The ignore rules now exclude generated Markdown reports and logs while allowing
`reports/.gitkeep`.

Priority: handled.

### 6. Pester CI output should stay out of source control

Running `Invoke-Pester -CI` creates `testResults.xml`.

The ignore rules now exclude that file.

Priority: handled.

## Recommended Changes

Before the first commit:

1. Stage the generated project files intentionally.
2. Confirm `prompts/` remains ignored.
3. Keep generated `reports/*.md` and `reports/*.log` out of git.
4. Keep `testResults.xml` out of git.
5. Review and commit the workflow cleanup and config-driven pipeline changes.

Before trusting `-Execute` broadly:

1. Add deeper mocked tests for destructive paths.
2. Add tests for service restart failure in Windows Update cache cleanup.
3. Add tests proving browser cache cleanup cannot touch cookies, passwords,
   bookmarks, profiles, or extensions.
4. Add tests proving protected folders and source-code folders are excluded
   by cleanup modules.

## Next Step

Run:

```powershell
git status --short --ignored
```

Then stage the intended files.

Do not stage `prompts/`, generated reports, `testResults.xml`, or
`future-upgrades.md`.
