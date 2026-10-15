# -*- coding: utf-8 -*-
"""
Faithful Python emulation of the VBScript SHA-1 in includes/db.asp.

Each function mirrors the VBScript source line-for-line, emulating
VBScript semantics:
  * Long = signed 32-bit, arithmetic wraps modulo 2^32
  * `x \\ y` truncates toward zero
  * And/Or/Xor are bitwise on two's-complement representations
  * Double->Long coercion of exact integers is lossless
"""
M32 = 0xFFFFFFFF


def wrap(x):
    x &= M32
    return x - 0x100000000 if x >= 0x80000000 else x


def tolong(x):
    """VBScript Double -> Long coercion (value is always an exact integer here)."""
    return int(x)


def Add32(x, y):
    xl = x & 0xFFFF
    xh = tolong((x - xl) / 0x10000)         # exact integer (Double in VBScript)
    yl = y & 0xFFFF
    yh = tolong((y - yl) / 0x10000)
    l = xl + yl
    h = xh + yh + (l // 0x10000 if l >= 0 else -((-l) // 0x10000))  # trunc toward zero
    l = l & 0xFFFF
    h = ((h + 0x8000) & 0xFFFF) - 0x8000
    return wrap(h * 0x10000 + l)


def ROL32(x, n):
    n = n & 31
    lo = x & 0xFFFF
    hiU = tolong((x - lo) / 0x10000) & 0xFFFF
    if n >= 16:
        lo, hiU = hiU, lo
        n = n - 16
    if n > 0:
        nlo = ((lo * 2 ** n) | (hiU // 2 ** (16 - n))) & 0xFFFF
        nhi = ((hiU * 2 ** n) | (lo // 2 ** (16 - n))) & 0xFFFF
        lo, hiU = nlo, nhi
    hv = hiU - (0x10000 if hiU >= 0x8000 else 0)
    return wrap(hv * 0x10000 + lo)


def Word32(b0, b1, b2, b3):
    hi = (b0 * 0x100) + b1
    lo = (b2 * 0x100) + b3
    hv = hi - (0x10000 if hi >= 0x8000 else 0)
    return wrap(hv * 0x10000 + lo)


def Hex32(x):
    r = x
    b = [0, 0, 0, 0]
    for i in range(3, -1, -1):
        b[i] = r & 0xFF
        r = tolong((r - b[i]) / 0x100)
    return "".join(f"{v:02X}" for v in b)


def SHA1Hex(s):
    # UTF-8 bytes
    data = s.encode("utf-8")
    n = len(data)
    bit_len = n * 8
    msg = bytearray(data)
    msg.append(0x80)
    while len(msg) % 64 != 56:
        msg.append(0)
    for i in range(7, -1, -1):
        msg.append((bit_len // (2 ** (8 * i))) & 0xFF)

    h0, h1, h2, h3, h4 = 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0
    for base in range(0, len(msg), 64):
        w = [0] * 80
        for j in range(16):
            w[j] = Word32(msg[base + j * 4], msg[base + j * 4 + 1],
                          msg[base + j * 4 + 2], msg[base + j * 4 + 3])
        for j in range(16, 80):
            w[j] = ROL32(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1)
        a, b, c, d, e = h0, h1, h2, h3, h4
        for j in range(80):
            if j < 20:
                f = (b & c) | ((~b) & d)
                k = 0x5A827999
            elif j < 40:
                f = b ^ c ^ d
                k = 0x6ED9EBA1
            elif j < 60:
                f = (b & c) | (b & d) | (c & d)
                k = 0x8F1BBCDC
            else:
                f = b ^ c ^ d
                k = 0xCA62C1D6
            temp = Add32(Add32(Add32(ROL32(a, 5), wrap(f)), Add32(e, wrap(k))), w[j])
            e, d, c, b, a = d, c, ROL32(b, 30), a, temp
        h0 = Add32(h0, a)
        h1 = Add32(h1, b)
        h2 = Add32(h2, c)
        h3 = Add32(h3, d)
        h4 = Add32(h4, e)
    return (Hex32(h0) + Hex32(h1) + Hex32(h2) + Hex32(h3) + Hex32(h4)).lower()


CASES = [
    ("", "da39a3ee5e6b4b0d3255bfef95601890afd80709"),
    ("abc", "a9993e364706816aba3e25717850c26c9cd0d89d"),
    ("12345678", "7c222fb2927d828af22f592134e8932480637c0d"),
    ("The quick brown fox jumps over the lazy dog", "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"),
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
     "84983e441c3bd26ebaae4aa1f95129e5e54670f1"),
    ("a" * 55, None),     # padding boundary: 55 + 1 + 8 = 64 (exactly one block)
    ("a" * 56, None),     # needs a second block
    ("a" * 63, None),
    ("a" * 64, None),
    ("a" * 65, None),
    ("a" * 100, None),    # multi-block message
    ("a" * 1000, None),   # many blocks
    ("PoliMusic<>&\"'\\", None),  # special chars (HTML/JS escaping relevance)
    ("mensaje con acentos: ñáéíóú", None),  # non-ASCII UTF-8 path
    ("message digest", None),
    ("abcdefghijklmnopqrstuvwxyz", None),
]

ok = True
for text, expected in CASES:
    got = SHA1Hex(text)
    import hashlib
    ref = hashlib.sha1(text.encode()).hexdigest()
    if expected is not None:
        status = "PASS" if got == expected else "FAIL(seed)"
        ok = ok and got == expected
    else:
        status = "PASS" if got == ref else "FAIL"
        ok = ok and got == ref
    print(f"{status} len={len(text):3d} got={got} ref={ref}")

print("ALL TESTS PASSED" if ok else "TESTS FAILED")
