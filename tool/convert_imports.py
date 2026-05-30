#!/usr/bin/env python3
"""Convert relative import/export directives in lib/ to package:smartbunda/... imports.

- Leaves dart:, package: imports untouched.
- Handles `import '...';`, `export '...';`, and conditional
  `import '...' if (cond) '...';` by converting each relative URI segment.
- Skips lib/screens/oracleJdk-26 (stray, non-dart).
"""
import os
import re

LIB = os.path.join(os.path.dirname(__file__), "..", "lib")
LIB = os.path.normpath(LIB)
PKG = "package:smartbunda/"

# matches a quoted URI; we only rewrite ones that are relative (start with ./ ../ or a bare name.dart)
URI_RE = re.compile(r"""(['"])([^'"]+)\1""")
DIRECTIVE_RE = re.compile(r"^\s*(import|export)\s+", re.MULTILINE)


def is_relative(uri: str) -> bool:
    if uri.startswith("dart:") or uri.startswith("package:"):
        return False
    return True  # ./, ../, or bare path within lib


def to_package(uri: str, file_dir: str) -> str:
    # Resolve the relative uri against the file's directory, then make it
    # relative to lib/ and prefix with package:smartbunda/.
    abs_target = os.path.normpath(os.path.join(file_dir, uri))
    rel_to_lib = os.path.relpath(abs_target, LIB)
    rel_to_lib = rel_to_lib.replace(os.sep, "/")
    return PKG + rel_to_lib


def convert_line(line: str, file_dir: str) -> str:
    if not DIRECTIVE_RE.match(line):
        return line

    def repl(m):
        quote, uri = m.group(1), m.group(2)
        if is_relative(uri):
            return f"{quote}{to_package(uri, file_dir)}{quote}"
        return m.group(0)

    return URI_RE.sub(repl, line)


def main():
    changed_files = 0
    changed_lines = 0
    for root, dirs, files in os.walk(LIB):
        if "oracleJdk-26" in root:
            continue
        for name in files:
            if not name.endswith(".dart"):
                continue
            path = os.path.join(root, name)
            file_dir = os.path.dirname(path)
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            new_lines = []
            file_changed = False
            for line in lines:
                nl = convert_line(line, file_dir)
                if nl != line:
                    file_changed = True
                    changed_lines += 1
                new_lines.append(nl)
            if file_changed:
                changed_files += 1
                with open(path, "w", encoding="utf-8", newline="") as f:
                    f.writelines(new_lines)
    print(f"Converted {changed_lines} directives across {changed_files} files.")


if __name__ == "__main__":
    main()
