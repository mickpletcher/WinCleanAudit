Scaffold a new GitHub-ready repository named WinCleanAudit.

Repository purpose:
A safety-first Windows cleanup and audit toolkit built with PowerShell.

Create this structure:

WinCleanAudit/
├── README.md
├── LICENSE
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── tasks/
│   └── windows-cleanup.yaml
├── src/
│   ├── WinCleanAudit.ps1
│   └── modules/
│       ├── TempCleanup.psm1
│       ├── WindowsUpdateCache.psm1
│       ├── RecycleBin.psm1
│       ├── OldLogCleanup.psm1
│       ├── BrowserCache.psm1
│       ├── StartupInventory.psm1
│       ├── LargeFileReport.psm1
│       ├── DuplicateDownloads.psm1
│       ├── InstalledApps.psm1
│       ├── DiskHealth.psm1
│       └── ReportWriter.psm1
├── reports/
│   └── .gitkeep
├── docs/
│   ├── safety-rules.md
│   ├── roadmap.md
│   └── usage-examples.md
└── tests/
    ├── README.md
    └── Pester/
        └── .gitkeep

Scaffold only.
Do not fully implement all cleanup logic yet.

Main requirements:
1. Create all files and folders.
2. Add placeholder PowerShell functions in each module.
3. Import all modules from src/WinCleanAudit.ps1.
4. Add command-line parameters:
   -DryRun
   -Execute
   -NoPrompt
   -ReportPath
5. Default to DryRun when no mode is specified.
6. Block -NoPrompt unless -Execute is used.
7. Add TODO comments where implementation will go.
8. Add basic report generation placeholder.
9. Add error handling stubs.
10. Add safety rules to docs/safety-rules.md.

README must include:
- Project overview
- Feature list
- Safety-first design
- Repo structure
- Basic usage examples
- Development roadmap
- Warning that this is scaffolded and not production-ready yet

tasks/windows-cleanup.yaml must include:
- Cleanup task names
- Audit task names
- Safety exclusions
- Report output settings

Use clean, readable PowerShell.
Keep the first commit scaffold-focused.
