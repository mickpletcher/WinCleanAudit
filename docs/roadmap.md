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
- Pester tests
- GitHub Actions CI

## Known Limitations

- Admin rights are needed for some system paths.
- Browser cache files can remain locked if browser processes are active.
- Hardware health data can vary by device and OS support.

## Future Enhancements

- Optional export to JSON and CSV
- Optional enterprise config profiles
- Endpoint integration patterns for Intune and ConfigMgr
- Module specific include and exclude path controls
- Signed release artifacts

## Release Checklist

- Syntax validation passes
- Pester suite passes
- DryRun default confirmed
- NoPrompt guard confirmed
- Report output reviewed
- Changelog reviewed
