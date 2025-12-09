# Toolbox

A collection of CLI tools and scripts.

## Structure

- `manifest.json` - Defines what gets installed and where, keyed by OS
- `install_win.ps1` - Windows installer (reads manifest)
- `install_macos.sh` - macOS installer (reads manifest, requires `jq`)
- `git/` - Git-related tools

## Manifest Format

```json
{
  "windows": {
    "copy": [["src", "dst"], ...],
    "alias": []
  },
  "macos": {
    "copy": [["src", "dst"], ...],
    "alias": []
  }
}
```

- **copy**: Array of `[source, destination]` pairs for files to install
- **alias**: Reserved for shell aliases (not yet implemented)

## Installation

**Windows:**
```powershell
.\install_win.ps1
```

**macOS:**
```bash
./install_macos.sh
```

