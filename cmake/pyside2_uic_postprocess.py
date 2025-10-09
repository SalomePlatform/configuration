#!/usr/bin/env python3
# Copyright (C) 2026  CEA, EDF, OPEN CASCADE
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# See http://www.salome-platform.org/
#

"""
This script file is post-processing the generated *_ui.py files by pyside2-uic to emulate
a subset of pyuic5 flags used in SALOME (notably --import-from and --resource-suffix).

It is intended to be used in the PYSIDE2_WRAP_UIC macro within UsePySide2.cmake, but can
also be used standalone in custom CMake commands.
"""

import argparse
import re
from pathlib import Path


def _rewrite_line(line: str, import_from: str, resource_suffix: str) -> tuple[str, bool]:
    changed = False

    # Match: import something_rc  [# comment]
    m = re.match(r"^(?P<indent>\s*)import\s+(?P<mod>[A-Za-z_][A-Za-z0-9_]*)\s*(?P<comment>#.*)?(?P<nl>\r?\n)?$", line)
    if not m:
        return line, False

    mod = m.group("mod")

    # Heuristic: treat *_rc (Qt resource modules) as candidates for rewrite.
    new_mod = mod
    if resource_suffix and mod.endswith("_rc"):
        base = mod[: -len("_rc")]
        new_mod = f"{base}{resource_suffix}"

    if new_mod != mod:
        changed = True

    indent = m.group("indent") or ""
    comment = (m.group("comment") or "").rstrip("\r\n")
    nl = m.group("nl") or "\n"

    if import_from:
        # Emulate PyQt's --import-from=<pkg> for resource imports.
        out = f"{indent}from {import_from} import {new_mod}"
        if comment:
            out += f"  {comment}"
        out += nl
        return out, True

    if new_mod != mod:
        out = f"{indent}import {new_mod}"
        if comment:
            out += f"  {comment}"
        out += nl
        return out, True

    return line, changed


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Post-process pyside2-uic generated Python files to emulate a subset of PyQt5 pyuic5 flags "
            "used in SALOME (notably --import-from and --resource-suffix)."
        )
    )
    parser.add_argument("--input", required=True, help="Path to generated *_ui.py file to patch in-place")
    parser.add_argument("--import-from", dest="import_from", default="", help="Package/module prefix for resource imports")
    parser.add_argument(
        "--resource-suffix",
        dest="resource_suffix",
        default="",
        help="Suffix to use instead of the default '_rc' for resource module imports (e.g. '_qrc')",
    )

    args = parser.parse_args()

    path = Path(args.input)
    text = path.read_text(encoding="utf-8", errors="replace")

    changed_any = False
    out_lines: list[str] = []
    for line in text.splitlines(keepends=True):
        new_line, changed = _rewrite_line(line, args.import_from, args.resource_suffix)
        out_lines.append(new_line)
        changed_any = changed_any or changed

    if changed_any:
        path.write_text("".join(out_lines), encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
