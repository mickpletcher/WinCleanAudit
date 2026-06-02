# Completed Upgrades

This file lists items from future-upgrades.md that are already implemented.

## Tier 1: Core Hardening

- [x] Keep DryRun as the default execution mode.
- [x] Enforce NoPrompt only when Execute is also provided.
- [x] Use a shared structured result contract across modules.
- [x] Resolve pipeline module entry points from configuration instead of a
  hard-coded dispatch map.
- [x] Classify access denied, locked file, missing path, and service control
  failures in report output.
- [x] Add a `-NoBrowserLaunch` switch for DryRun automation runs.
- [x] Add path normalization tests for protected locations and cloud sync
  exclusions.

## Tier 2: Quality and Dev Experience

- [x] Maintain a Pester suite that covers all modules.
- [x] Run CI for PowerShell tests and Markdown linting.
- [x] Add lightweight GitHub project governance with a project spec, issue
  templates, and a pull request template.

## Tier 3: Platform and Enterprise Features

- [x] Generate Markdown reports with per module result sections.
- [x] Generate and open an HTML report during DryRun.
- [x] Add optional JSON and CSV report exports.
- [x] Add centralized policy profiles for enterprise endpoint fleets.
- [x] Add optional scheduled task installer for managed recurring runs.
- [x] Add integration templates for Intune and ConfigMgr deployment.
- [x] Add optional Windows Event Log output for enterprise monitoring.
- [x] Add an optional report retention policy for old generated reports and
  logs.
