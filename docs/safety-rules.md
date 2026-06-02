# Safety Rules

## Core Behavior

- Default mode is DryRun.
- No cleanup runs unless Execute is explicitly passed.
- NoPrompt is blocked unless Execute is also passed.
- Destructive actions require confirmation unless Execute and NoPrompt are
  both used.

## Protected Locations

Never clean content from:

- Desktop
- Documents
- Pictures
- Videos
- Music
- OneDrive
- Dropbox
- Google Drive
- Git repositories
- Source code folders

## Error Handling

- Access denied errors are captured and reported.
- Locked file conditions are captured and skipped.
- Missing paths are classified and reported.
- Service control errors are classified and reported.
- Execute mode records attempted deletes, skipped cleanup items, and service
  actions in ExecutionLog.
- Windows Update cache cleanup validates restarted services.
- Module failure does not stop the full run.

## Testing Safety

- Tests must mock destructive actions.
- Tests must not empty recycle bin.
- Tests must not delete temp files, browser cache, old logs, or update cache
  content.
- Tests must not modify startup configuration, apps, disks, or services.

## Common Report Fields

- TaskName
- Module
- Status
- Mode
- ItemsScanned
- ItemsModified
- EstimatedBytes
- RecoveredBytes
- ActionsTaken
- Warnings
- Errors
- Recommendations
- Details
- ExecutionLog
- Duration
