Create a Windows system cleanup tool using PowerShell.

Project goal:
Build a safe, report-first cleanup utility that audits and optionally cleans common Windows system clutter.

Create the following files:

```text
windows-system-cleanup/
  README.md
  cleanup-windows.ps1
  tasks/windows-cleanup.yaml
  reports/.gitkeep
```

The script must support two modes:

```powershell
.\cleanup-windows.ps1 -DryRun
.\cleanup-windows.ps1 -Execute
```

Default behavior must be `-DryRun`.

Required cleanup and audit areas:

1. Temp folders

   * Scan user temp folder.
   * Scan Windows temp folder.
   * Report file count and estimated size.
   * Delete only in `-Execute` mode.

2. Windows Update cache

   * Analyze `C:\Windows\SoftwareDistribution\Download`.
   * Report size.
   * Only clean in `-Execute` mode.
   * Stop and restart Windows Update services safely if required.
   * Include error handling if access is denied.

3. Recycle Bin

   * Report current size if possible.
   * Empty only in `-Execute` mode.
   * Include confirmation before emptying.

4. Old log files

   * Search common log locations.
   * Include `.log`, `.etl`, `.tmp`, and `.dmp`.
   * Only target files older than 30 days.
   * Report count and size.
   * Delete only in `-Execute` mode.

5. Browser cache with confirmation

   * Detect Chrome, Edge, Firefox, and Brave cache folders.
   * Report estimated size.
   * Do not delete browser cache unless the user confirms.
   * Skip locked files without crashing.

6. Startup app inventory

   * List startup items from:

     * Startup folders
     * Registry Run keys
     * Scheduled Tasks that trigger at logon
   * Do not disable anything.
   * Output findings to the report.

7. Large file report

   * Scan user profile folders.
   * Find files over 500 MB.
   * Exclude system folders.
   * Do not delete anything.
   * Output path, size, and last modified date.

8. Duplicate download report

   * Scan the Downloads folder.
   * Detect duplicate files using file hash.
   * Report duplicates grouped by hash.
   * Do not delete anything.

9. Installed app inventory

   * List installed applications from Windows uninstall registry keys.
   * Include name, version, publisher, install date if available.
   * Output to report.

10. Disk health report

* Report disk usage.
* Report SMART health where possible.
* Report volume free space.
* Do not make disk changes.

Safety rules:

* Never delete anything from Desktop, Documents, Pictures, Videos, Music, OneDrive, Dropbox, Google Drive, Git repositories, or source-code folders.
* Never delete files unless `-Execute` is explicitly passed.
* Require confirmation before destructive actions.
* Add `-NoPrompt` support for automation, but only allow it with `-Execute`.
* Log all actions.
* Handle access-denied errors cleanly.
* Continue running if one section fails.

Report requirements:
Generate a Markdown report in the `reports` folder named like:

```text
cleanup-report-YYYYMMDD-HHMMSS.md
```

The report must include:

* Computer name
* User name
* Date and time
* PowerShell version
* Whether the run was DryRun or Execute
* Summary table of each cleanup area
* Estimated reclaimable space
* Actions taken
* Errors encountered
* Recommendations

README requirements:
Document:

* What the tool does
* How to run dry run mode
* How to run execute mode
* Safety protections
* What is never deleted
* Example report output
* Administrator permission notes

Also create `tasks/windows-cleanup.yaml` describing the cleanup tasks, safety rules, and report output.

Make the code clean, modular, and heavily commented.
