#!/usr/bin/env python3
"""Run every example against the built single-file bundle, headlessly.

The examples are written for Roblox: they fetch the build with
``game:HttpGet`` + ``loadstring`` and colour things with ``Color3``. This runner
swaps the loader for the bundle's own entry point and provides the small subset
of Roblox globals the examples touch. Everything else -- windows, layouts,
components, styles, themes, registries, config -- is the real shipped code path,
so a failure here is a real failure of the example or of the library.

It also cross-checks the style ids the examples reference against the ids the
shipped registry actually exposes, so an example can never silently fall back to
a default style.

Usage: python3 tools/verify-examples.py [path/to/bundle.luau]
Exit status is non-zero if any example fails or a referenced style is missing.
"""

import glob
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_BUNDLE = ROOT / "build" / "NEVAHEXUI.luau"
LUAU = ROOT / ".tools" / "luau" / "luau"
ENTRY = "__NEVA_Init"

# Roblox globals the examples use. Declared as locals in the same chunk as the
# example body, so they are visible to it without touching the global table.
PRELUDE = """
local Color3 = {
\tfromRGB = function(r, g, b)
\t\treturn { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }
\tend,
\tnew = function(r, g, b)
\t\treturn { R = r or 0, G = g or 0, B = b or 0 }
\tend,
\tfromHSV = function(h, s, v)
\t\treturn { R = s or 0, G = v or 0, B = h or 0 }
\tend,
\tfromHex = function(hex)
\t\tlocal clean = tostring(hex):gsub("#", "")
\t\treturn {
\t\t\tR = tonumber(clean:sub(1, 2), 16) / 255,
\t\t\tG = tonumber(clean:sub(3, 4), 16) / 255,
\t\t\tB = tonumber(clean:sub(5, 6), 16) / 255,
\t\t}
\tend,
}
"""

IDS_SCRIPT = """
local ids = %s:StyleIds()
print("count=" .. tostring(#ids))
for _, id in ipairs(ids) do
\tprint("ID:" .. id)
end
""" % ENTRY

LOADER = re.compile(r"local\s+NEVAHEXUI\s*=\s*loadstring\([^\n]*\)\(\)")
STYLE_REF = re.compile(r'(?:Id|StyleId)\s*=\s*"([^"]+)"')


def split_bundle(path):
    """Return the bundle with its trailing `return <entry>` removed."""
    lines = path.read_text().rstrip("\n").split("\n")
    last = lines[-1].strip()
    if last != "return " + ENTRY:
        raise SystemExit(
            "unexpected bundle ending %r; expected 'return %s'" % (last, ENTRY)
        )
    return "\n".join(lines[:-1])


def registered_style_ids(library):
    scratch = pathlib.Path("/tmp/neva-style-ids.luau")
    scratch.write_text(library + IDS_SCRIPT)
    result = subprocess.run(
        [str(LUAU), str(scratch)], capture_output=True, text=True, timeout=120
    )
    if result.returncode != 0:
        raise SystemExit("could not list registered styles:\n" + result.stderr.strip())
    return {
        line[len("ID:") :].strip()
        for line in result.stdout.split("\n")
        if line.startswith("ID:")
    }


def main(argv):
    bundle_path = pathlib.Path(argv[1]) if len(argv) > 1 else DEFAULT_BUNDLE
    if not bundle_path.exists():
        raise SystemExit(
            "bundle not found: %s (run `node tools/build.mjs` first)" % bundle_path
        )
    library = split_bundle(bundle_path)

    failures = []
    failed_examples = 0
    examples = sorted(glob.glob(str(ROOT / "examples" / "*.luau")))
    if not examples:
        raise SystemExit("no examples found in examples/")

    referenced = {}
    for path in examples:
        name = pathlib.Path(path).name
        source = pathlib.Path(path).read_text()
        for match in STYLE_REF.finditer(source):
            referenced.setdefault(match.group(1), name)

        body, swaps = LOADER.subn("local NEVAHEXUI = " + ENTRY, source)
        if swaps != 1:
            failures.append((name, "no loadstring line found"))
            failed_examples += 1
            print("FAIL %s: no loadstring line found" % name)
            continue

        chunk = (
            library
            + "\n"
            + PRELUDE
            + "\n"
            + body
            + '\nprint("[ok] end of example reached")\n'
        )
        scratch = pathlib.Path("/tmp/neva-example.luau")
        scratch.write_text(chunk)
        result = subprocess.run(
            [str(LUAU), str(scratch)], capture_output=True, text=True, timeout=300
        )
        output = (result.stdout + result.stderr).strip().split("\n")
        notable = [line for line in output if line.strip()][-4:]
        if result.returncode == 0:
            print("PASS %s" % name)
        else:
            failures.append((name, "\n".join(notable)))
            failed_examples += 1
            print("FAIL %s" % name)
        for line in notable:
            print("     " + line)

    ids = registered_style_ids(library)
    unknown = sorted(style for style in referenced if style not in ids)
    print(
        "\nstyle catalogue: %d registered, %d referenced by examples"
        % (len(ids), len(referenced))
    )
    for style in unknown:
        print("  UNKNOWN style id %r referenced by %s" % (style, referenced[style]))
        failures.append((referenced[style], "unknown style id %r" % style))

    print(
        "\n%d/%d examples ran cleanly, %d unknown style ids"
        % (len(examples) - failed_examples, len(examples), len(unknown))
    )
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
