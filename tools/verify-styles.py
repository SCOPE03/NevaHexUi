#!/usr/bin/env python3
"""Sweep every registered style through the headless back end and report defects.

This is a regression net for a class of bug that static analysis cannot see:

  * a style or component wiring a button event (MouseButton1Down/Up/Click,
    Activated) to an instance class that does not own it -- in Roblox that
    raises "X is not a valid member of Frame", and a Frame that is not Active
    never receives InputBegan either, so the interaction silently dies;
  * a style that fails while building or updating its view;
  * an interactive element that cannot actually be clicked.

The headless back end is deliberately strict about instance classes, so these
surface here instead of in an executor.

Usage: python3 tools/verify-styles.py [path/to/bundle.luau]
Exit status is non-zero if any check fails.
"""

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_BUNDLE = ROOT / "build" / "NEVAHEXUI.luau"
LUAU = ROOT / ".tools" / "luau" / "luau"
ENTRY = "__NEVA_Init"

PROBE = r"""
local NEVAHEXUI = {ENTRY}

local window = NEVAHEXUI:CreateWindow({ Name = "Style sweep", Layout = "Floating", Theme = "dark" })
local tab = window:CreateTab({ Name = "Main" })
local section = tab:CreateSection({ Name = "Every style" })

local function pathOf(instance)
	local parts = {}
	while instance do
		table.insert(parts, 1, tostring(instance.Name))
		instance = instance.Parent
	end
	return table.concat(parts, "/")
end

-- 1. One component per registered style, so every renderer actually runs.
local created, failures = 0, {}
for _, styleId in ipairs(NEVAHEXUI:StyleIds()) do
	local record = NEVAHEXUI:GetStyle(styleId)
	if not record or not record.Component then
		table.insert(failures, styleId .. ": no component recorded")
	else
		local ok, err = pcall(function()
			section:Create(record.Component, {
				Name = styleId, Flag = "sweep." .. styleId, Style = { Id = styleId },
			})
		end)
		if ok then
			created += 1
		else
			table.insert(failures, styleId .. ": " .. tostring(err))
		end
	end
end
print("FAILURES=" .. tostring(#failures))
for _, entry in ipairs(failures) do print("  FAIL " .. entry) end

-- 2. Press events must land on instances that own them.
local host = window.Host
local miswired = host.UnsupportedPressConnections or {}
print("MISWIRED=" .. tostring(#miswired))
for _, entry in ipairs(miswired) do
	print(("  %s -> %s  at %s"):format(entry.Event, entry.ClassName, pathOf(entry.Instance)))
end

-- 3. Style/runtime errors raised while rendering.
local errors = window.Context.Diagnostics.Errors or {}
print("ERRORDIAG=" .. tostring(#errors))
for _, entry in ipairs(errors) do
	print("  ERR " .. tostring(entry.Message or entry))
end

-- 4. Interactions that only work if the instance class is right.
local input = {
	UserInputType = "Enum.UserInputType.MouseButton1",
	Position = host.vector2(10, 10),
	KeyCode = "Enum.KeyCode.Unknown",
}
host.emit(window.TitleBar, "MouseButton1Down", input)
local pressed = window.Dragging == true
host.emit(window.TitleBar, "MouseButton1Up", input)
local released = window.Dragging == false
print(("TITLEBAR=%s/%s"):format(tostring(pressed), tostring(released)))

-- 5. The window tree must hang off a parented ScreenGui, otherwise the whole
--    interface is built and never shown.
local rootGui = window.Host.Root
print("GUIPARENT=" .. tostring(window.GuiParent or window.Host.ParentSource or "unknown"))
print("ROOTCHAIN=" .. tostring(
	rootGui ~= nil and rootGui.Parent ~= nil and window.Root ~= nil and window.Root.Parent == rootGui))

local picker = section:CreateColorPicker({ Name = "Sweep colour", Flag = "SweepColour" })
local preview = picker.View and picker.View.Input
local before = picker.View and picker.View.Open
host.click(preview)
local toggled = picker.View and picker.View.Open ~= before
print("PICKER=" .. tostring(toggled ~= nil and toggled == true))

local copyable = section:CreateCopyableInput({ Name = "Sweep copy", Flag = "SweepCopy", Default = "value" })
local copySurface = copyable.View and copyable.View.Copy
print("COPYCLASS=" .. tostring(copySurface and copySurface.ClassName))
"""

# The probe is Lua, so its table braces cannot go through str.format.
PROBE = PROBE.replace("{ENTRY}", ENTRY)


def main(argv):
    bundle_path = pathlib.Path(argv[1]) if len(argv) > 1 else DEFAULT_BUNDLE
    if not bundle_path.exists():
        raise SystemExit("bundle not found: %s (run `node tools/build.mjs` first)" % bundle_path)

    lines = bundle_path.read_text().rstrip("\n").split("\n")
    if lines[-1].strip() != "return " + ENTRY:
        raise SystemExit("unexpected bundle ending %r" % lines[-1])

    scratch = pathlib.Path("/tmp/neva-style-sweep.luau")
    scratch.write_text("\n".join(lines[:-1]) + PROBE)
    result = subprocess.run([str(LUAU), str(scratch)], capture_output=True, text=True, timeout=300)
    output = result.stdout + result.stderr
    print(output.strip())

    warnings = sorted({line.strip() for line in output.split("\n") if "unknown property" in line})

    def count(name):
        match = re.search(r"^%s=(\d+)$" % name, output, re.M)
        if not match:
            print("\n%s: probe did not report a value" % name)
            return -1
        return int(match.group(1))

    problems = []
    for name in ("FAILURES", "MISWIRED", "ERRORDIAG"):
        value = count(name)
        if value != 0:
            problems.append("%s=%d" % (name, value))
    for name in ("TITLEBAR=true/true", "PICKER=true", "COPYCLASS=TextButton", "ROOTCHAIN=true"):
        if name not in output:
            problems.append("expected " + name)

    # A property that no style declares is configuration that silently does
    # nothing, so it counts as a problem rather than a note.
    if warnings:
        print("%d schema warning(s) about properties the style does not declare:" % len(warnings))
        for line in warnings:
            print("  " + line)
        problems.append("UNKNOWN_PROPERTIES=%d" % len(warnings))

    print("\nstyle sweep: %d problem(s)" % len(problems))
    for line in problems:
        print("  " + line)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
