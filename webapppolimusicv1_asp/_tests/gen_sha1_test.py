# -*- coding: utf-8 -*-
"""Generate a VBScript unit test for the SHA1Hex implementation in db.asp."""
import os

ROOT = r"C:/Users/gabri/source/repos/AppWebAvGabrielMaldonado/webapppolimusicv1_asp"
src = open(os.path.join(ROOT, "includes/db.asp"), encoding="utf-8").read()
start = src.index("Function Add32")
end = src.index("%>")
funcs = src[start:end]

test = funcs + "\n" + '''Dim cases(5, 1)
cases(0, 0) = "" : cases(0, 1) = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
cases(1, 0) = "abc" : cases(1, 1) = "a9993e364706816aba3e25717850c26c9cd0d89d"
cases(2, 0) = "12345678" : cases(2, 1) = "7c222fb2927d828af22f592134e8932480637c0d"
cases(3, 0) = "The quick brown fox jumps over the lazy dog" : cases(3, 1) = "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"
cases(4, 0) = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" : cases(4, 1) = "248d6a61d20638b8e5c026930c3e6039a33ce459"
Dim i, ok, got
ok = True
For i = 0 To 4
    got = SHA1Hex(cases(i, 0))
    If got = cases(i, 1) Then
        WScript.Echo "PASS [" & cases(i, 0) & "] -> " & got
    Else
        ok = False
        WScript.Echo "FAIL [" & cases(i, 0) & "] expected " & cases(i, 1) & " got " & got
    End If
Next
If ok Then WScript.Echo "ALL TESTS PASSED" Else WScript.Echo "TESTS FAILED"
'''

out = os.path.join(ROOT, "_tests", "sha1_test.vbs")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w", encoding="ascii") as f:
    f.write(test)
print("written:", out)
