# Roadmap

## v1.0.0 Completed

- Core framework and pipeline
- Configuration, safety, logging, report writer
- Temp cleanup
- Windows Update cache audit and optional cleanup
- Recycle bin audit and optional cleanup
- Old log audit and optional cleanup
- Browser cache audit and optional cleanup
- Startup inventory
- Large file report
- Duplicate downloads report
- Installed apps inventory
- Disk health report
- Optional JSON and CSV report exports
- HTML report browser launch suppression for automation
- Failure classification for access denied, locked file, missing path, and
  service control errors
- Rollback safe execution log for attempted deletes, skipped items, and
  service actions
- Windows Update service restart validation
- Redirected known folder and enterprise Folder Redirection protection
- Enterprise config profiles
- Report retention
- Event Log output
- Category specific Event Log event IDs
- Endpoint integration patterns for Intune and ConfigMgr
- Intune detection checks for scheduled task, config, and recent reports
- ConfigMgr compliance baseline examples
- MSI and winget style packaging templates
- Pester tests
- GitHub Actions CI

## Known Limitations

- Admin rights are needed for some system paths.
- Browser cache files can remain locked if browser processes are active.
- Hardware health data can vary by device and OS support.
- More destructive-path mock coverage is recommended before broad Execute use.

## Future Enhancements

- Centralized privilege precheck for modules that require elevation
- Strict configuration schema validation
- Module timeout controls
- Per module maximum item limits
- Browser profile data denylist enforcement
- Cleanup allowlists per module
- Module specific include and exclude path controls
- Signed release artifacts

## Release Checklist

- Syntax validation passes
- Pester suite passes
- DryRun default confirmed
- NoPrompt guard confirmed
- NoBrowserLaunch automation path confirmed
- Report output reviewed
- ExecutionLog output reviewed for Execute paths
- Changelog reviewed
