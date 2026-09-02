# Limbo Hub UI

A compact, dark Roblox Luau UI library customized from WindUI. Limbo Hub includes a two-line branded header, executor/version badges, compact sidebar navigation, configuration persistence, transparent watermark support, notifications, and a draggable reopen launcher.

## Load the library

```luau
local LimboUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/aleyn6969/limbo/refs/heads/main/dist/main.lua"
))()
```

## Run the reusable template

```luau
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/aleyn6969/limbo/refs/heads/main/templates/LimboTemplate.lua"
))()
```

The template opens **Information** by default and includes:

- Limbo Hub branding and transparent watermark
- Information / Main / Settings navigation
- Discord community paragraph and copy action
- Per-game config persistence under `LimboHUB/<Game Name>/Config/`
- Save, load, delete, and auto-load profile controls

## Development

```bash
npm install
npm run build
```

The production bundle is written to `dist/main.lua`.

## Credits and license

Limbo Hub UI is based on [WindUI](https://github.com/Footagesus/WindUI) by Footagesus and remains available under the MIT License. Icons are supplied by the upstream icon package, including Lucide Icons.
