# erpctrl Plugin Repository

This repository is a dual Claude Code / Codex plugin package, not the erpctrl CLI source tree.

## Repository Shape

- `.claude-plugin/` contains the Claude Code plugin manifest and Claude marketplace metadata.
- `.codex-plugin/` contains the Codex plugin manifest.
- `skills/erpctrl/SKILL.md` runs existing erpctrl scenarios from natural-language requests.
- `skills/erpctrl-scenario/SKILL.md` creates new scenario JSON files under `%APPDATA%\erpctrl\my_scenarios\`.
- The actual `erpctrl.exe` CLI is not bundled here. It is bootstrapped at skill runtime from the internal shared server.

## Non-Negotiable Runtime Rules

- Do not add `*.exe`, `*.dll`, or `*.pdb` artifacts to this repository.
- Keep all edited files UTF-8 encoded.
- Preserve the README-first workflow in both skills: runtime work must read `%APPDATA%\erpctrl\README.md` after bootstrap/update.
- Preserve the `--vars` calling convention: pass one comma-delimited string argument, never a PowerShell splat array or whitespace-separated tokens.
- Values containing commas must be injected through environment variables, not through `--vars`.
- Do not print or persist ERP passwords.
- User-created scenarios belong in `%APPDATA%\erpctrl\my_scenarios\`, not in mirrored `scenarios\`.

## Validation

Run these checks after plugin metadata or skill changes:

```powershell
$env:PYTHONIOENCODING = 'utf-8'
python C:\Users\donghun.lee\.codex\skills\.system\plugin-creator\scripts\validate_plugin.py .
```

Also parse all plugin JSON files and confirm `skills/**/SKILL.md` frontmatter remains valid YAML.
