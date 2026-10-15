# -*- coding: utf-8 -*-
"""Extract PoliMusic resources and generate missing placeholder media."""
import os, zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT = r"C:/Users/gabri/source/repos/AppWebAvGabrielMaldonado/webapppolimusicv1_asp"
ZIP = os.path.join(ROOT, "SongFilesAndImages_resources.zip")

ORANGE = (251, 86, 7)      # FB5607
PURPLE = (131, 56, 236)    # 8338EC
DARK   = (33, 37, 53)      # 212529
WHITE  = (255, 255, 255)

# ---------------------------------------------------------------- extract zip
with zipfile.ZipFile(ZIP) as z:
    z.extractall(ROOT)
print("[ok] zip extracted ->", [d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d))])

# ---------------------------------------------------------------- font loader
def load_font(size, bold=True):
    fonts = [
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/seguisb.ttf",
        "C:/Windows/Fonts/DejaVuSans-Bold.ttf",
    ]
    for f in fonts:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()

# ------------------------------------------------------------- gradient maker
def gradient(w, h, c1, c2, diagonal=True):
    small = 64
    img = Image.new("RGB", (small, small))
    px = img.load()
    for y in range(small):
        for x in range(small):
            t = (x + y) / (2 * (small - 1)) if diagonal else y / (small - 1)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            px[x, y] = (r, g, b)
    return img.resize((w, h), Image.BICUBIC)

# --------------------------------------------------------------- music note
def draw_note(draw, cx, cy, scale, color):
    """Simple eighth-note glyph drawn with shapes."""
    # note head
    hw = int(46 * scale)
    hh = int(34 * scale)
    hx = cx - int(52 * scale)
    hy = cy + int(30 * scale)
    draw.ellipse([hx - hw // 2, hy - hh // 2, hx + hw // 2, hy + hh // 2], fill=color)
    # stem
    sx = hx + hw // 2 - int(6 * scale)
    sw = max(int(7 * scale), 3)
    draw.rectangle([sx, cy - int(95 * scale), sx + sw, hy], fill=color)
    # flag
    fw = int(52 * scale)
    fh = int(58 * scale)
    draw.polygon([
        (sx + sw, cy - int(95 * scale)),
        (sx + sw + fw, cy - int(95 * scale) + int(14 * scale)),
        (sx + sw + int(26 * scale), cy - int(95 * scale) + fh),
        (sx + sw, cy - int(95 * scale) + fh),
    ], fill=color)

def fit_text(draw, text, max_w, start):
    size = start
    while size > 12:
        font = load_font(size)
        if draw.textlength(text, font=font) <= max_w:
            return font
        size -= 2
    return load_font(12)

def make_cover(path, title, caption, c1, c2, size=640, note=True):
    img = gradient(size, size, c1, c2)
    d = ImageDraw.Draw(img, "RGBA")
    if note:
        draw_note(d, size // 2, int(size * 0.36), size / 640.0, (255, 255, 255, 60))
    font = fit_text(d, title, size - 90, 64)
    bbox = d.textbbox((0, 0), title, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((size - tw) / 2, size * 0.58), title, font=font, fill=(255, 255, 255, 235))
    cap_font = fit_text(d, caption, size - 120, 26)
    cb = d.textbbox((0, 0), caption, font=cap_font)
    cw = cb[2] - cb[0]
    d.text(((size - cw) / 2, size * 0.58 + th + 26), caption, font=cap_font, fill=(255, 255, 255, 160))
    img.save(path)
    print("[ok]", os.path.relpath(path, ROOT))

# ------------------------------------------------------------ album covers
os.makedirs(os.path.join(ROOT, "albumImages"), exist_ok=True)
album_variants = [
    ("album1.png", "Rock Album",      ORANGE, DARK),
    ("album2.png", "Relax Music",     PURPLE, (58, 34, 122)),
    ("album3.png", "Retro Album Music", ORANGE, PURPLE),
    ("album4.png", "Classic Album",   (214, 74, 6), (74, 32, 148)),
    ("album5.png", "Country Album",   PURPLE, ORANGE),
]
for fname, title, c1, c2 in album_variants:
    make_cover(os.path.join(ROOT, "albumImages", fname), title, "POLIMUSIC ALBUM", c1, c2)

# ----------------------------------------------------------- artist images
os.makedirs(os.path.join(ROOT, "ArtistImages"), exist_ok=True)
artists = [
    ("artist1.jpg", "Juan Gabriel",    "JG", ORANGE, PURPLE),
    ("artist2.jpg", "Ana Gabriel",     "AG", PURPLE, (58, 34, 122)),
    ("artist3.jpg", "Mariah Carey",    "MC", ORANGE, DARK),
    ("artist4.jpg", "Elvis Presley",   "EP", (214, 74, 6), (74, 32, 148)),
    ("artist5.png", "Edward Sheeran",  "ES", PURPLE, ORANGE),
]
for fname, name, initials, c1, c2 in artists:
    img = gradient(640, 640, c1, c2)
    d = ImageDraw.Draw(img, "RGBA")
    draw_note(d, 320, 250, 0.75, (255, 255, 255, 55))
    font = load_font(150)
    bbox = d.textbbox((0, 0), initials, font=font)
    tw = bbox[2] - bbox[0]
    d.text(((640 - tw) / 2, 320), initials, font=font, fill=(255, 255, 255, 240))
    nf = fit_text(d, name, 560, 40)
    nb = d.textbbox((0, 0), name, font=nf)
    nw = nb[2] - nb[0]
    d.text(((640 - nw) / 2, 520), name, font=nf, fill=(255, 255, 255, 200))
    img.save(os.path.join(ROOT, "ArtistImages", fname))
    print("[ok] ArtistImages/" + fname)

# ------------------------------------------------------------- user avatar
os.makedirs(os.path.join(ROOT, "userImages"), exist_ok=True)
img = gradient(400, 400, PURPLE, ORANGE)
d = ImageDraw.Draw(img, "RGBA")
draw_note(d, 200, 150, 0.5, (255, 255, 255, 70))
font = load_font(120)
bbox = d.textbbox((0, 0), "U", font=font)
d.text(((400 - (bbox[2] - bbox[0])) / 2, 210), "U", font=font, fill=(255, 255, 255, 240))
img.save(os.path.join(ROOT, "userImages", "username1.png"))
print("[ok] userImages/username1.png")

# ----------------------------------------------------------------- favicon
os.makedirs(os.path.join(ROOT, "images"), exist_ok=True)
def favicon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, size - 1, size - 1], fill=ORANGE)
    s = size / 48.0
    draw_note(d, int(24 * s), int(22 * s), s, WHITE)
    return img
frames = [favicon(s) for s in (16, 32, 48)]
frames[0].save(os.path.join(ROOT, "images", "favicon.ico"),
               sizes=[(16, 16), (32, 32), (48, 48)], append_images=frames[1:])
print("[ok] images/favicon.ico")

# ------------------------------------------------------------ verify contents
for folder in ["SongFiles", "UserImages", "PlaylistImages", "albumImages", "ArtistImages", "userImages"]:
    p = os.path.join(ROOT, folder)
    print(folder, "->", sorted(os.listdir(p)) if os.path.isdir(p) else "MISSING")
