#!/usr/bin/env python3
"""Run every example against the built single-file bundle, headlessly.

The examples are written for Roblox: they fetch the build with
``game:HttpGet`` + ``loadstring`` and colour things with ``Color3``. This runner
swaps the loader for the bundle's own entry point and provides the small subset
of Roblox globals the examples touch. Everything else -- windows, layouts,
components, styles, themes, registries, config -- is the real shipped code path,
so a failure here is a real failure of the example or of the library.

Usage: python3 tools/verify-examples.py [path/to/bundle.luau]
Exit status is non-zero if any example fails.
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

LOADER = re.compile(r"local\s+NEVAHEXUI\s*=\s*loadstring\([^\n]*\)\(\)")


def split_bundle(path):
    lines = path.read_text().rstrip("\n").split("\n")
    if lines[-1].strip() != "return " + ENTRY:
        raise SystemExit(
            "unexpected bundle ending %r; expected 'return %s'" % (lines[-1], ENTRY)
        )
    return "\n".join(lines[:-1])


def main(argv):
    bundle_path = pathlib.Path(argv[1]) if len(argv) > 1 else DEFAULT_BUNDLE
    if not bundle_path.exists():
        raise SystemExit("bundle not found: %s (run `node tools/build.mjs` first)" % bundle_path)
    library = split_bundle(bundle_path)

    failures = []
    examples = sorted(glob.glob(str(ROOT / "examples" / "*.luau")))
    if not examples:
        raise SystemExit("no examples found in examples/")

    for path in examples:
        source = pathlib.Path(path).read_text()
        body, swaps = LOADER.subn("local NEVAHEXUI = " + ENTRY, source)
        if swaps != 1:
            failures.append((path, "could not find the loadstring line"))
            print("FAIL %s: no loadstring line found" % pathlib.Path(path).name)
            continue
        chunk = library + "\n" + PRELUDE + "\n" + body + '\nprint("[ok] end of example reached")\n'
        scratch = pathlib.Path("/tmp/neva-example.luau")
        scratch.write_text(chunk)
        result = subprocess.run(
            [str(LUAU), str(scratch)], capture_output=True, text=True, timeout=300
        )
        output = (result.stdout + result.stderr).strip().split("\n")
        notable = [line for line in output if line.strip()][-4:]
        name = pathlib.Path(path).name
        if result.returncode == 0:
            print("PASS %s" % name)
        else:
            failures.append((path, "\n".join(notable)))
            print("FAIL %s" % name)
        for line in notable:
            print("     " + line)

    print("\n%d/%d examples ran cleanly" % (len(examples) - len(failures), len(examples)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
