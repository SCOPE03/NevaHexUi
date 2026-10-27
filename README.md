# NEVAHEXUI

A unified Roblox Luau UI framework: one component API, one theme engine, and a
configurable **style registry** where several genuinely different renderers exist
for the same component type — selectable per component, per category, or globally,
and editable at runtime in the built-in **Style Studio**.

> Status: source complete and building; runtime verification is in progress (see
> *Verification* below). Examples 01–05 are included; more are on the way.

---

## Load it

The single-file build is checked in, so you can load it directly:

```lua
local NEVAHEXUI = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/SCOPE03/NevaHexUi/main/build/NEVAHEXUI.luau"
))()

local Window = NEVAHEXUI:CreateWindow({
	Name = "NEVAHEXUI",
	Layout = "Sidebar",           -- Sidebar | TopTabs | Floating | Compact | IconSidebar | MultiColumn
	Theme = "dark",
})

local Tab = Window:CreateTab({ Name = "Main" })
local Section = Tab:CreateSection({ Name = "Example" })

Section:CreateToggle({
	Name = "Enabled",
	Flag = "Enabled",
	Default = true,
	Style = { Id = "toggle.rounded" },
	Callback = function(value)
		print("Enabled:", value)
	end,
})

Section:CreateSlider({
	Name = "Speed",
	Flag = "Speed",
	Min = 1, Max = 100, Default = 50,
	Style = { Id = "slider.filled" },
})
```

Runnable examples live in [`examples/`](examples) — start with
[`01-quick-start.luau`](examples/01-quick-start.luau).

---

## Two styles of the same component, in one window

```lua
local Toggle1 = Section:CreateToggle({
	Name = "Style 1 - Modern",
	Flag = "Toggle1",
	Default = true,
	Style = {
		Id = "toggle.rounded",
		Configuration = { AccentColor = Color3.fromRGB(239, 68, 68), CornerRadius = 12, Width = 44, Height = 24 },
	},
})

local Toggle2 = Section:CreateToggle({
	Name = "Style 2 - Compact",
	Flag = "Toggle2",
	Default = false,
	Style = {
		Id = "toggle.compact",
		Configuration = { AccentColor = Color3.fromRGB(70, 140, 255), CornerRadius = 3, Width = 36, Height = 20 },
	},
})
```

Every registered id is a distinct renderer. Configuration resolves through a
documented cascade:

1. built-in component defaults
2. the selected style's defaults
3. `Requires` preset chain
4. category configuration (`StyleConfiguration = { Toggle = {...} }`)
5. per-component `Style.Configuration`
6. runtime overrides (`SetStyleProperty`, `SetStyleConfiguration`)

Inspect any resolved result with `Component:GetEffectiveConfiguration()` and
`Component:ExplainConfiguration()`.

---

## Style Studio

Click the **S** button in the title bar (or call `Window:OpenStudio()`):

- **catalog** of every component type that has real renderers, with counts
- **two live preview slots** (Style 1 / Style 2) — real components, sandboxed callbacks
- **schema-driven inspector** — sliders, toggles, colour pickers, text fields and
  cyclers generated from the selected style's own property schema
- **Apply / Preset / Export / Reset** — push the style onto a live component,
  register it as a reusable preset, or emit Luau

---

## What's implemented

| Area | Count | Notes |
|---|---|---|
| Style renderers | 50 | across 26 component types |
| Component types | 26 | buttons, toggles, checkboxes, radios, sliders, ranges, text inputs, keybinds, colour pickers, labels, badges, progress, loaders, images, tables, trees, logs, graphs, notifications, dialogs |
| Layouts | 6 | Sidebar, TopTabs, Floating, Compact, IconSidebar, MultiColumn |
| Themes | see `NEVAHEXUI:ListThemes()` | dark, light, red-accent, neon, glass, minimal, high-contrast and more |
| Public API | — | `CreateWindow`, `CreateTab`, `CreateSection/Groupbox/Card/Collapsible/DependencyBox`, `Notify`, `Dialog`, `RegisterStyle`, `SetComponentStyle`, `SetCategoryStyle`, `SaveConfig`/`LoadConfig`/`ExportConfig` |

Not implemented yet: Dropdown, Multiselect, Command Palette, and Studio catalog search.

---

## Build and test

```bash
node tools/build.mjs                     # writes build/NEVAHEXUI.luau, .min.lua, test bundle, report
luau build/nevahexui-tests.luau          # runs the automated suite under the mock host
```

The bundler resolves `require("NEVA:...")` into a single file (42 modules),
topologically sorted, and fails loudly on unknown modules, cycles, or a module
without a return.

---

## Verification

- **Static**: every module parses; `luau-analyze` reports no syntax errors.
- **Runtime (automated)**: the test bundle runs the library headlessly against the
  in-memory host, covering construction, registry sync, style switching with state
  preservation, precedence, presets, dependencies, themes, layouts, the Studio,
  configuration round-trips and teardown.
- **Not yet done**: testing inside a real Roblox client/executor. Nothing here has
  been exercised against live Roblox instances, so treat rendering as unverified
  until you run it.

## Licence

MIT — see [`LICENSE`](LICENSE) and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
