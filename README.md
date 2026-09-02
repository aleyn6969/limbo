
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

The template first opens a **Key System** gate. The main Information/Main/Settings window is only created after the configured validation API returns `{ "valid": true }`.

Configure the placeholder in `templates/LimboTemplate.lua`:

```luau
local KEY_API_URL = "https://domain.com/api/validate"
```

Expected request body:

```json
{"key":"...","gameId":0,"placeId":0,"userId":0,"executor":"..."}
```

Expected successful response:

```json
{"valid":true}
```

All API errors, non-2xx status codes, malformed JSON, and `{ "valid": false }` responses fail closed and keep the feature window locked.

After validation, the template opens **Information** by default and includes:

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
