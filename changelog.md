# Changelog

All notable changes to this repository should be recorded here.

This changelog tracks changes to the prompt repository itself. It does not replace the `CHANGELOG.md` that the generated `WinCleanAudit` project will eventually contain.

## Unreleased

### Added

* Added complete Codex implementation prompts for steps `06` through `17`:
  * `06-Implement-Old-Log-Cleanup.md`
  * `07-Implement-Browser-Cache-Cleanup.md`
  * `08-Implement-Startup-Inventory.md`
  * `09-Implement-Large-File-Report.md`
  * `10-Implement-Duplicate-Downloads.md`
  * `11-Implement-Installed-Apps-Inventory.md`
  * `12-Implement-Disk-Health-Report.md`
  * `13-Implement-Reporting-Engine.md`
  * `14-Add-Pester-Tests.md`
  * `15-Add-GitHub-Actions.md`
  * `16-Write-Documentation.md`
  * `17-Prepare-Release-v1.md`
* Added `assessment.md` for a quick repo overview, implementation status, validation summary, known risks, and recommended changes.
* Added this `changelog.md` to record future repository changes.
* Added `github-copilot-implementation-prompt.md` to orchestrate running prompts `01` through `17` in GitHub Copilot.
* Added `completed-upgrades.md` to track implemented items from the upgrade roadmap.

### Changed

* Reworked `01-CreateWindowsCleanupTool.md` into a complete standalone scaffold prompt.
* Reworked `02-Build-Core-Framework.md` into a complete standalone framework prompt.
* Reworked `03-Implement-Temp-Cleanup.md` into a complete standalone Temp Cleanup prompt.
* Reworked `04-Implement-Windows-Update-Cache.md` into a complete standalone Windows Update Cache prompt.
* Standardized all numbered prompts `01` through `17` to include:
  * `Goal`
  * `Target Files`
  * `Functional Requirements`
  * `Safety Requirements`
  * `Testing Requirements`
  * `Documentation Requirements`
  * `Acceptance Criteria`
* Standardized the reporting API across prompts to:
  * `New-WinCleanReport`
  * `ConvertTo-ReadableSize`
  * `Add-ReportSection`
  * `Write-MarkdownReport`
* Added a shared result object contract to the framework prompt and aligned module prompts to it.
* Updated module prompts to use configuration, module loading, and pipeline execution instead of hard-coded runner calls.
* Added explicit Pester test targets for Temp Cleanup and Windows Update Cache.
* Clarified Large File Report scan scope to avoid protected user folders and cloud-sync paths.
* Pinned Markdown lint guidance to `DavidAnson/markdownlint-cli2-action@v18`.
* Updated `README.md` to reference `completed-upgrades.md`.
* Updated `.gitignore` to keep `future-upgrades.md` local and out of git pushes.
* Updated `.gitignore` so `prompts/` remains local-only and generated report/log files are ignored.
* Updated `.gitignore` to ignore Pester `testResults.xml`.
* Updated `assessment.md` after generated app files were added.
* Rewrote `README.md` for novice users with safer quick start guidance, plain-language module descriptions, and clearer run mode explanations.
* Replaced placeholder README badge URLs with the real GitHub repository path.
* Removed the unnecessary `actions/setup-python@v5` step from the PowerShell test workflow.
* Refactored pipeline module dispatch to resolve entry points from `tasks/windows-cleanup.yaml`.
* Added tests for configuration-driven pipeline dispatch.
* Added the upgrade tracking rule to `future-upgrades.md` and documented that implemented upgrade items must be reflected in `completed-upgrades.md`, `changelog.md`, and `assessment.md`.

### Removed

* Removed duplicate untracked prompt files:
  * `01-Scaffold-Repository.md`
  * `CreateWindowsCleanupTool.md`

### Validation

* PowerShell syntax check passed for all `.ps1` and `.psm1` files.
* `.\src\WinCleanAudit.ps1 -DryRun` completed successfully.
* Pester passed: 38 tests passed, 0 failed.

### Notes

* The generated `WinCleanAudit` PowerShell project now exists in the repository.
* Generated reports and logs are ignored under `reports/`.
