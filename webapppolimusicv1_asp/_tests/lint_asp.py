# -*- coding: utf-8 -*-
"""Structural lint for the PoliMusic classic ASP application.

Checks per .asp file:
  1. <%@ Language=VBScript %> directive (pages only, not include fragments)
  2. <% ... %> delimiter balance
  3. HTML tag pairing (ASP blocks masked; self-closing tags ignored)
  4. VBScript string/paren/block structure (all code blocks joined first,
     so Do...Loop pairs split across <% %> blocks validate correctly)

Known VBScript subtleties handled to avoid false positives:
  - single-line  If ... Then <stmt>   (no matching End If)
  - Exit Sub / Exit Function / Exit For / Exit Do
  - On Error Resume Next  ("Next" is not a loop closer here)
  - rs.MoveNext           ("MoveNext" is one identifier, not a Next closer)
  - line continuations " _"
"""
import os
import re
import sys

ROOT = r"C:/Users/gabri/source/repos/AppWebAvGabrielMaldonado/webapppolimusicv1_asp"

PAIRED_TAGS = [
    "div", "table", "form", "section", "main", "details", "thead", "tbody",
    "tr", "td", "th", "span", "a", "button", "select", "label", "header",
    "footer", "nav", "p", "h1", "h2", "h3", "summary", "svg", "symbol",
    "use", "script", "style", "audio", "optgroup", "fieldset",
]
VOID_TAGS = ["input", "br", "meta", "link", "img", "source"]


def strip_vb_strings_comments(code):
    """Replace string literals and ' comments with spaces (keeps structure)."""
    out = []
    i, n = 0, len(code)
    in_str = False
    while i < n:
        ch = code[i]
        if in_str:
            if ch == '"':
                if i + 1 < n and code[i + 1] == '"':
                    out.append("  ")
                    i += 2
                    continue
                in_str = False
                out.append(" ")
                i += 1
                continue
            out.append(" " if ch != "\n" else "\n")
            i += 1
            continue
        if ch == '"':
            in_str = True
            out.append(" ")
            i += 1
            continue
        if ch == "'":
            j = code.find("\n", i)
            if j < 0:
                j = n
            out.append(" " * (j - i))
            i = j
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def count_balanced(norm, name, opener_re, closer_re):
    o = len(re.findall(opener_re, norm))
    c = len(re.findall(closer_re, norm))
    return o, c


def check_vbscript(joined_code, path, errs):
    """Validate VBScript structure of all code blocks of a file, joined.

    joined_code: all non-directive <% ... %> block bodies, joined by newlines.
    """
    stripped = strip_vb_strings_comments(joined_code)

    # parenthesis balance
    depth = 0
    for idx, ch in enumerate(stripped):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0:
                line = stripped[:idx].count("\n") + 1
                errs.append(f"{path}: unbalanced ')' near code line {line}")
                depth = 0
    if depth != 0:
        errs.append(f"{path}: parenthesis imbalance of {depth}")

    # normalize whitespace, drop 'On Error Resume Next' tokens and continuations
    norm = re.sub(r"[ \t]+", " ", stripped)
    norm = re.sub(r"(?i)\bResume\s+Next\b", " ", norm)      # phantom Next
    norm = re.sub(r"[ \t]+_[ \t]*\n", " ", norm)            # line continuations

    # block If openers: 'If ... Then' with nothing (no statement) after Then.
    # single-line 'If ... Then <stmt>' is a complete statement: not counted.
    n_block_if = 0
    for ln in norm.split("\n"):
        ln = ln.strip()
        m = re.match(r"(?i)^If\b.*\bThen\b(.*)$", ln)
        if m and not m.group(1).strip():
            n_block_if += 1
    n_end_if = len(re.findall(r"(?i)\bEnd\s+If\b", norm))

    # Exit <kw> is not an opener for the corresponding block, and neither is
    # the keyword of 'End <kw>' (both counted by a naive \b<kw>\b)
    checks = [
        ("If",       n_block_if, "End If",
                      n_end_if),
        ("For",      len(re.findall(r"(?i)(?<!Exit )\bFor\b", norm)), "Next",
                      len(re.findall(r"(?i)\bNext\b", norm))),
        ("Do",       len(re.findall(r"(?i)(?<!Exit )\bDo\b", norm)), "Loop",
                      len(re.findall(r"(?i)\bLoop\b", norm))),
        ("Function", len(re.findall(r"(?i)(?<!Exit )(?<!End )\bFunction\b", norm)), "End Function",
                      len(re.findall(r"(?i)\bEnd\s+Function\b", norm))),
        ("Sub",      len(re.findall(r"(?i)(?<!Exit )(?<!End )\bSub\b", norm)), "End Sub",
                      len(re.findall(r"(?i)\bEnd\s+Sub\b", norm))),
        ("With",     len(re.findall(r"(?i)(?<!Exit )(?<!End )\bWith\b", norm)), "End With",
                      len(re.findall(r"(?i)\bEnd\s+With\b", norm))),
        ("Select",   len(re.findall(r"(?i)(?<!Exit )(?<!End )\bSelect\b", norm)), "End Select",
                      len(re.findall(r"(?i)\bEnd\s+Select\b", norm))),
        ("Class",    len(re.findall(r"(?i)(?<!Exit )(?<!End )\bClass\b", norm)), "End Class",
                      len(re.findall(r"(?i)\bEnd\s+Class\b", norm))),
    ]
    for name, o, closer, c in checks:
        if o != c:
            errs.append(f"{path}: {name} x{o} vs {closer} x{c}")


def lint_file(path):
    errs = []
    rel = os.path.relpath(path, ROOT)
    relslash = rel.replace(os.sep, "/")
    content = open(path, encoding="utf-8").read()

    # @ Language directive present (include fragments are exempt)
    is_include = relslash.startswith("includes/")
    if not is_include and not content.lstrip().lower().startswith("<%@ language"):
        errs.append(f"{rel}: missing <%@ Language=VBScript %> directive")

    # <% %> balance
    opens = len(re.findall(r"<%", content))
    closes = len(re.findall(r"%>", content))
    if opens != closes:
        errs.append(f"{rel}: <% count {opens} != %> count {closes}")

    # HTML tag pairing (ASP blocks masked so server-side markup does not count)
    html = re.sub(r"<%[\s\S]*?%>", "ASP", content, flags=re.S)
    html = re.sub(r"<!--[\s\S]*?-->", " ", html)            # strip comments
    html = re.sub(r"<([a-zA-Z][a-zA-Z0-9]*)((?:\s[^>]*?)?)/>", " ", html)  # self-closing
    for tag in PAIRED_TAGS:
        o = len(re.findall(r"<" + tag + r"(?=[\s>])", html, flags=re.I))
        c = len(re.findall(r"</" + tag + r">", html, flags=re.I))
        if o != c:
            errs.append(f"{rel}: <{tag}> {o} open vs {c} close")

    # VBScript structure: join every code block so constructs that legitimately
    # span <% %> boundaries (Do While ... / ... Loop) are checked as one unit
    blocks = []
    for m in re.finditer(r"<%([\s\S]*?)%>", content, flags=re.S):
        code = m.group(1)
        if code.lstrip().startswith("@"):
            continue  # directive, not code
        blocks.append(code)
    check_vbscript("\n".join(blocks), rel, errs)

    # include targets exist
    for m in re.finditer(r'<!--#include\s+file="([^"]+)"\s*-->', content):
        inc = m.group(1).replace("/", os.sep)
        base = os.path.dirname(path)
        target = os.path.normpath(os.path.join(base, inc))
        if not os.path.exists(target):
            errs.append(f"{rel}: include target missing: {inc}")

    return errs


def main():
    all_errs = []
    files = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in
                       ("_tests", "__pycache__", ".workbuddy-ai")]
        for f in filenames:
            if f.lower().endswith(".asp"):
                files.append(os.path.join(dirpath, f))
    for f in sorted(files):
        errs = lint_file(f)
        status = "OK  " if not errs else "FAIL"
        print(f"[{status}] {os.path.relpath(f, ROOT)}")
        for e in errs:
            print(f"        - {e}")
        all_errs.extend(errs)

    print()
    if all_errs:
        print(f"{len(all_errs)} issue(s) found")
        sys.exit(1)
    print(f"All {len(files)} ASP files passed structural checks")


if __name__ == "__main__":
    main()
