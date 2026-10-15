# PoliMusic — project memory

Classic ASP (VBScript) Spotify-like app. Repo root = web app root (deploy as IIS app).

## Stack & conventions
- Classic ASP + VBScript, `Option Explicit`, ADODB.Command parameterized queries (no string SQL)
- Conn string: Server=apoc;Database=BDD_PoliMusic;User Id=usr_polimusic;Password=Politecnica1;Encrypt=True;TrustServerCertificate=True
- Auth: Session("USER_ID"/"USER_NAME"/"USER_TYPE"); 0=normal, 1=admin. RequireLogin/RequireAdmin in db.asp
- Palette: #FB5607 orange, #8338EC purple, #212529 dark, #E9ECEF light (CSS vars in styles.css)
- Media paths in DB use `~/...`; MediaURL() maps them to app URLs via VRoot() (APPL_MD_PATH based)
- Every list page: `<script>window.PM_SONGS = <%= SongsJson() %></script>` + `SongTable(...)`; player lives in layout.asp, logic in js/app.js (window.PM namespace)
- PRG pattern: form POST → SetFlash → Redirect; Session("PM_FLASH") rendered by layout.asp
- CSS gotcha: any element toggled with the `hidden` attribute needs the global `[hidden]{display:none!important}` rule (class display rules beat the UA rule)

## Testing without IIS
- `_tests/lint_asp.py` — structural lint of all .asp files (run: python _tests/lint_asp.py)
- `_tests/sha1_emulation.py` — validates the pure-VBScript SHA-1 (cscript blocked here)
- `_tests/gen_preview.py` → `_preview/*.html` static previews; `_tests/shot_preview.js` screenshots them
  (run from the managed node workspace with NODE_PATH set; Playwright Chromium already installed)

## Environment gotchas
- msedge.exe is blocked (exits 0 silently); use Playwright Chromium
- Python: `C:/Users/gabri/.workbuddy-ai/binaries/python/versions/3.13.12/python.exe` (no venv at envs/default)
- Node packages: managed workspace `.../binaries/node/workspace`, install via npm-cli.js, run with NODE_PATH

## Seed data / DB
- 5 songs (only bensound-adventure.mp3 shipped in the ZIP), 5 artists, 5 albums, 5 playlists,
  3 users (userNormal, userAdmin, username1 — all password `12345678`; username1 stores SHA-1 hex)
- Admin CRUD: admin/songs.asp (with TBL_PLAYER linking), admin/artists.asp, admin/albums.asp (tracklist)
