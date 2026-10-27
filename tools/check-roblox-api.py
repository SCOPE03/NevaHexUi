#!/usr/bin/env python3
"""Validate every Roblox instance property and enum name the library uses.

The headless back end cannot catch a wrong *property name*: `host.new("ImageLabel",
{ ImageColor = ... })` looks fine there and is silently dropped in Roblox, because
the back end assigns through pcall. This checks the names against Roblox's own API
dump instead, so instance-level mistakes are found here rather than in an executor.

Checks:
  * `host.new("Class", { Property = ... })` and `Helpers.new(host, "Class", {...})`
    against that class and its superclasses;
  * option tables handed to the instance-building helpers (Surface.text,
    Surface.panel, Surface.hit, Helpers.frame/button/text/scroller) against the
    union of all class properties, since the target class is chosen inside them;
  * `host.set(instance, { Property = ... })` against the union too;
  * `host.enumItem("Enum", "Item")` against the real enums.

Usage: python3 tools/check-roblox-api.py [path/to/api-dump.json]
Exit status is non-zero when anything unknown is found.
"""

import json
import pathlib
import re
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
DUMP_URL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"
DUMP_CACHE = pathlib.Path("/tmp/roblox-api-dump.json")

# Tables whose keys become instance properties. The two strict ones name a class
# in the call; the loose ones pick the class inside the helper, so they are
# checked against the union of every class.
STRICT_TABLES = (
    re.compile(r'host\.new\(\s*"([A-Za-z0-9_]+)"\s*,\s*\{'),
    re.compile(r'Helpers\.new\(\s*host\s*,\s*"([A-Za-z0-9_]+)"\s*,\s*\{'),
)
LOOSE_TABLES = (
    re.compile(r'Surface\.text\(\s*ctx\s*,\s*[^,]+,\s*\{'),
    re.compile(r'Surface\.hit\(\s*ctx\s*,\s*[^,]+,\s*\{'),
    re.compile(r'Helpers\.(?:frame|button|text|scroller)\(\s*host\s*,\s*[^,]+,\s*\{'),
)

# Surface.panel is different: its table carries framework options (Background,
# Token, Stroke, Button, ...) that the helper turns into instance properties
# itself, so it is validated against the helper's own option list instead.
PANEL_TABLE = re.compile(r'Surface\.panel\(\s*ctx\s*,\s*[^,]+,\s*\{')
SET_TABLE = re.compile(r'host\.set\(\s*[^,]+,\s*\{')
ENUM_ITEM = re.compile(r'enumItem\(\s*"([A-Za-z0-9_]+)"\s*,\s*"([A-Za-z0-9_]+)"\s*\)')
KEY = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=')

# Not instance properties: table plumbing the helpers normalise away themselves.
IGNORED_KEYS = {"Parent", "ClassName"}


def load_dump(argv):
    if len(argv) > 1:
        return json.loads(pathlib.Path(argv[1]).read_text())
    if not DUMP_CACHE.exists():
        print("downloading the Roblox API dump ...")
        try:
            urllib.request.urlretrieve(DUMP_URL, DUMP_CACHE)
        except Exception:
            subprocess.run(["curl", "-sL", "-o", str(DUMP_CACHE), DUMP_URL], check=True)
    return json.loads(DUMP_CACHE.read_text())


def build_index(dump):
    classes = {entry["Name"]: entry for entry in dump["Classes"]}
    resolved = {}

    def properties(name, seen=None):
        if name in resolved:
            return resolved[name]
        entry = classes.get(name)
        if entry is None:
            resolved[name] = set()
            return resolved[name]
        seen = seen or set()
        if name in seen:
            return set()
        seen.add(name)
        found = set()
        parent = entry.get("Superclass")
        if parent:
            found |= properties(parent, seen)
        for member in entry["Members"]:
            if member["MemberType"] == "Property":
                found.add(member["Name"])
        resolved[name] = found
        return found

    for name in classes:
        properties(name)

    every = set()
    for name in resolved:
        every |= resolved[name]
    enums = {entry["Name"]: {item["Name"] for item in entry["Items"]} for entry in dump["Enums"]}
    return classes, resolved, every, enums


def panel_options():
    text = (ROOT / "src" / "Styles" / "Surface.luau").read_text()
    start = text.index("function Surface.panel")
    end = text.find("\nfunction ", start + 10)
    body = text[start : end if end != -1 else len(text)]
    return set(re.findall(r"options\.([A-Za-z_][A-Za-z0-9_]*)", body))


def line_of(text, index):
    return text.count("\n", 0, index) + 1


def table_keys(text, brace_index):
    """Top-level keys of the Lua table whose '{' is at brace_index."""
    keys = []
    depth = 0
    index = brace_index
    while index < len(text):
        char = text[index]
        if char == "{":
            depth += 1
            if depth == 1:
                # keys sharing the opening line
                end = text.find("\n", index)
                remainder = text[index + 1 : end if end != -1 else len(text)]
                remainder = remainder.split("}", 1)[0]
                for match in re.finditer(r'([A-Za-z_][A-Za-z0-9_]*)\s*=', remainder):
                    keys.append((match.group(1), line_of(text, index + 1 + match.start())))
        elif char == "}":
            depth -= 1
            if depth == 0:
                return keys
        elif char == "\n" and depth == 1:
            match = KEY.match(text[index + 1 : index + 120])
            if match:
                keys.append((match.group(1), line_of(text, index + 1)))
        index += 1
    return keys


def main(argv):
    dump = load_dump(argv)
    classes, properties, every_property, enums = build_index(dump)
    allowed_panel = panel_options()
    print("API dump: %d classes, %d enums" % (len(classes), len(enums)))

    problems = []
    checked = 0

    for path in sorted(pathlib.Path(ROOT / "src").rglob("*.luau")):
        text = path.read_text()
        relative = path.relative_to(ROOT)

        for pattern in STRICT_TABLES:
            for match in pattern.finditer(text):
                class_name = match.group(1)
                brace = text.index("{", match.end() - 1)
                allowed = properties.get(class_name)
                if allowed is None:
                    problems.append("%s:%d: unknown class %r" % (relative, line_of(text, match.start()), class_name))
                    continue
                for key, line in table_keys(text, brace):
                    if key in IGNORED_KEYS:
                        continue
                    checked += 1
                    if key not in allowed:
                        problems.append("%s:%d: %s has no property %r" % (relative, line, class_name, key))

        for match in PANEL_TABLE.finditer(text):
            brace = text.index("{", match.end() - 1)
            for key, line in table_keys(text, brace):
                checked += 1
                if key not in allowed_panel:
                    problems.append("%s:%d: Surface.panel has no option %r" % (relative, line, key))

        for pattern in LOOSE_TABLES + (SET_TABLE,):
            for match in pattern.finditer(text):
                brace = text.index("{", match.end() - 1)
                for key, line in table_keys(text, brace):
                    if key in IGNORED_KEYS:
                        continue
                    checked += 1
                    if key not in every_property:
                        problems.append("%s:%d: no Roblox class has a property %r" % (relative, line, key))

        for match in ENUM_ITEM.finditer(text):
            enum_name, item_name = match.group(1), match.group(2)
            checked += 1
            if enum_name not in enums:
                problems.append("%s:%d: unknown enum Enum.%s" % (relative, line_of(text, match.start()), enum_name))
            elif item_name not in enums[enum_name]:
                problems.append("%s:%d: Enum.%s has no item %r" % (relative, line_of(text, match.start()), enum_name, item_name))

    print("checked %d property/enum references" % checked)
    if problems:
        print("\n%d problem(s):" % len(problems))
        for problem in problems:
            print("  " + problem)
        return 1
    print("every property and enum name resolves against the Roblox API")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
