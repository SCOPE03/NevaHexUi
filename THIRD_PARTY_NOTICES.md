# Third-party notices and source provenance

NEVAHEXUI is an independent implementation. **No third-party source code is
vendored into this repository.** The Roblox UI libraries below were reviewed as
*behavioural and architectural references* during design; the components, styles,
theme engine, style registry, Style Studio and every other file under `src/` were
written for this project.

That means the repository currently redistributes no third-party code, so no
upstream notice is required here. If any source is vendored in future, this file
must be updated with the library, its licence text and the exact files affected.

## Repositories reviewed

| Repository | Licence | Use |
|---|---|---|
| [Footagesus/WindUI](https://github.com/Footagesus/WindUI) | MIT | Behaviour reference: component set, config persistence, notifications |
| [deividcomsono/Obsidian](https://github.com/deividcomsono/Obsidian) | MIT | Behaviour reference: flags, dependency boxes, theme switching |
| [veraci-ty/obsidian](https://github.com/veraci-ty/obsidian) | MIT | Behaviour reference: reactive update model |
| [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent) | MIT | Behaviour reference: control layout, theming surface |
| [biggaboy212/Maclib](https://github.com/biggaboy212/Maclib) | MIT | Behaviour reference: window chrome and animation feel |
| [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) | MIT | Behaviour reference: tab boxes, group boxes, keybinds |
| [cascadeui/Cascade](https://github.com/cascadeui/Cascade) | MIT | Behaviour reference: typed retained-mode component model |
| [huoadf/LinoriaLib](https://github.com/huoadf/LinoriaLib) | MIT | Fork of LinoriaLib — reviewed for mobile input handling, not counted separately |
| [TunelSeeker/UI-Library](https://github.com/TunelSeeker/UI-Library) | MIT | Fork of LinoriaLib — diffed for unique changes only |
| [cruzeht915/roblox-ui-component-library](https://github.com/cruzeht915/roblox-ui-component-library) | MIT | Behaviour reference: component abstraction shapes |
| [Distendo/UUI](https://github.com/Distendo/UUI) | MIT | Behaviour reference: element composition |
| [metatablecat/Recreate](https://github.com/metatablecat/Recreate) | Apache-2.0 | Behaviour reference: layout abstraction |
| [SiriusSoftwareLtd/Rayfield](https://github.com/SiriusSoftwareLtd/Rayfield) | Apache-2.0 | Behaviour reference: configuration and notification surfaces |
| [Nebula-Softworks/Luna-Interface-Suite](https://github.com/Nebula-Softworks/Luna-Interface-Suite) | BSD-3-Clause | Behaviour reference: keybind UI |
| [IEnemyFiles/Luna-Interface](https://github.com/IEnemyFiles/Luna-Interface) | BSD-3-Clause | Fork reviewed for unique controls |
| [Sypse/Sypse-UI](https://github.com/Sypse/Sypse-UI) | none found | Studied for behaviour only; independently implemented |
| [xHeptc/Kavo-UI-Library](https://github.com/xHeptc/Kavo-UI-Library) | none found | Studied for behaviour only; independently implemented |
| [ImInsane-1337/Roblox-UI](https://github.com/ImInsane-1337/Roblox-UI) | none found | Unlicensed fork of an inaccessible upstream; behaviour only |
| [Snxdfer/Roblox-UI-Libraries](https://github.com/Snxdfer/Roblox-UI-Libraries) | none found | Archive; CompKiller loads from the unlicensed `Snxdfer/back-ups-for-libs` — behaviour only, no vendoring |
| [sirius-menu/rayfield](https://github.com/sirius-menu/rayfield) | none found (no licence file on that path) | Behaviour only; the Apache-2.0 fork above was used as the reference |

### Unresolved links

These were reported or requested but could not be verified, so nothing was derived
from them and they are recorded as unresolved rather than assumed:

- `venyx-ui/venyx` — repository not found (nearest verified project: the archived,
  unlicensed `Stefanuk12/Venyx-UI-Library`)
- `shlexware/Orion` — repository not found; no confirmed mirror located
- `luagkkkk/LuaInterface` — repository not found
- `metatablecatmaid/Recreate` — not found; the verified project is `metatablecat/Recreate`

## Assets

NEVAHEXUI ships no image or audio assets. Examples that reference
`rbxassetid://` ids do so for demonstration only; those assets remain the property
of their owners and are not redistributed here.
