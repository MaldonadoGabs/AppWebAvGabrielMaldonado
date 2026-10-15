# -*- coding: utf-8 -*-
"""Generate static HTML previews of the PoliMusic classic ASP app.

Since IIS is not available in this environment, this script reproduces the
exact markup the ASP pages would render (same includes/layout.asp shell,
same includes/songs.asp SongTable output) using the seed data from
BDD_PoliMusic.sql, so the design (palette #FB5607 / #8338EC / #212529 /
#E9ECEF) can be inspected and screenshotted in a browser.

Output: _preview/*.html  (assets are referenced relatively: ../css, ../js, ..)
"""
import html
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "_preview")

# ---------------------------------------------------------------- seed data
ARTISTS = {
    1: ("Juan", "Gabriel", "artist1.jpg"),
    2: ("Ana", "Gabriel", "artist2.jpg"),
    3: ("Mariah", "Carey", "artist3.jpg"),
    4: ("Elvis", "Presley", "artist4.jpg"),
    5: ("Edward", "Sheeran", "artist5.png"),
}
ALBUMS = {
    1: ("Rock Album", "1976", "album1.png"),
    2: ("Relax Music", "2000", "album2.png"),
    3: ("Retro Album Music", "1980", "album3.png"),
    4: ("Classic Album", "1950", "album4.png"),
    5: ("Country Album", "1990", "album5.png"),
}
SONGS = {
    1: ("Adventure", "bensound-adventure.mp3", 0),
    2: ("Dreams", "bensound-dreams.mp3", 1),
    3: ("Energy", "bensound-energy.mp3", 2),
    4: ("Scifi", "bensound-scifi.mp3", 3),
    5: ("Tomorrow", "bensound-tomorrow.mp3", 4),
}
TRACKLIST = {1: [1, 2, 3, 4, 5], 2: [2, 3], 3: [1, 3, 5], 4: [2, 4], 5: [3, 5]}
PLAYER = {1: [1, 2], 2: [1, 2], 3: [1, 3], 4: [1, 4], 5: [1, 5]}
PLAYLISTS = {
    1: ("Playlist 1", "2026-12-12", "1", "default.jpg", [1, 2, 3, 4, 5]),
    2: ("Playlist 2", "2026-12-13", "0", "playlist1.png", [1, 2, 3, 4]),
    3: ("Playlist 3", "2026-12-14", "0", "playlist2.png", [4]),
    4: ("Playlist 4", "2026-12-15", "1", "playlist3.png", [1, 3]),
    5: ("Playlist 5", "2026-12-16", "0", "playlist4.png", [5]),
}
MONTHS = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def H(s):
    return html.escape(str(s), quote=True)


def fmt_date(iso):
    y, m, d = iso.split("-")
    return f"{int(d)} {MONTHS[int(m)]} {y}"


def media_url(p):
    """Mirror of MediaURL(): strip a leading '~/', prefix app root."""
    s = str(p or "")
    if s.startswith("~/"):
        return "../" + s[2:]
    return s


def song_extras(sid):
    """Artists / albums / cover exactly like SONG_COLS (sorted by name)."""
    arts = sorted((ARTISTS[a] for a in PLAYER[sid]), key=lambda a: a[0])
    arts_s = ", ".join(f"{a[0]} {a[1]}".strip() for a in arts)
    albs = sorted((ALBUMS[t] for t in TRACKLIST if sid in TRACKLIST[t]),
                  key=lambda a: a[0])
    albs_s = ", ".join(a[0] for a in albs)
    cover = "../albumImages/" + albs[0][2] if albs else ""
    return arts_s, albs_s, cover


def song_rows(ids):
    """Full song records in catalog order of the given ids."""
    out = []
    for sid in ids:
        name, path, plays = SONGS[sid]
        arts, albs, cover = song_extras(sid)
        out.append({"id": sid, "name": name, "artists": arts,
                    "albums": albs, "cover": cover, "plays": plays,
                    "src": media_url("~/songFiles/" + path)})
    return sorted(out, key=lambda s: s["name"])


def songs_json(songs):
    """Mirror of SongsJson()."""
    return json.dumps([{"i": s["id"], "t": s["name"], "a": s["artists"],
                        "al": s["albums"], "img": s["cover"],
                        "s": s["src"]} for s in songs],
                      separators=(",", ":"))


# ------------------------------------------------------- shared ASP output
def svg_sprite():
    syms = [
        ("i-play", "M8 5v14l11-7z"),
        ("i-pause", "M6 5h4v14H6zm8 0h4v14h-4z"),
        ("i-prev", "M6 6h2v12H6zm3.5 6L18 18V6z"),
        ("i-next", "M16 6h2v12h-2zM6 6l8.5 6L6 18z"),
        ("i-note", "M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"),
        ("i-search", "M15.5 14h-.79l-.28-.27a6.5 6.5 0 1 0-.7.7l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0A4.5 4.5 0 1 1 14 9.5 4.5 4.5 0 0 1 9.5 14z"),
        ("i-logout", "M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5-5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z"),
        ("i-plus", "M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"),
        ("i-trash", "M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"),
        ("i-pencil", "M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 0 0 0-1.41l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"),
        ("i-close", "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"),
        ("i-volume", "M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0 0 14 7.97v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"),
        ("i-list", "M3 13h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm4 4h14v-2H7v2zm0 4h14v-2H7v2zM7 7v2h14V7H7z"),
        ("i-user", "M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"),
    ]
    body = "\n".join(
        f'  <symbol id="{i}" viewBox="0 0 24 24"><path d="{d}"/></symbol>'
        for i, d in syms)
    return ('<svg xmlns="http://www.w3.org/2000/svg" style="display:none" '
            'aria-hidden="true">\n' + body + "\n</svg>")


def topbar(user, is_admin, active=""):
    admin_badge = ('<span class="badge badge-admin">Administrator</span>'
                   if is_admin else
                   '<span class="badge badge-user">User</span>')
    manage = ""
    if is_admin:
        manage = """
      <div class="dropdown">
        <button type="button" class="navlink dropdown-toggle" aria-haspopup="true" aria-expanded="false">Manage <span class="caret"></span></button>
        <div class="dropdown-menu" role="menu">
          <a role="menuitem" href="#"><svg class="icon"><use href="#i-note"/></svg> Songs</a>
          <a role="menuitem" href="#"><svg class="icon"><use href="#i-user"/></svg> Artists</a>
          <a role="menuitem" href="#"><svg class="icon"><use href="#i-list"/></svg> Albums</a>
        </div>
      </div>"""
    nav_links = [("Home", "dashboard-user.html" if not is_admin
                  else "dashboard-admin.html", ""),
                 ("Artists", "catalog-user.html", ""),
                 ("Albums", "catalog-user.html", ""),
                 ("Playlists", "playlists-user.html", "")]
    nav = "\n".join(
        f'    <a class="navlink" href="{href}">{label}</a>'
        for label, href, _ in nav_links)
    return f"""
<header class="topbar">
  <a class="brand" href="dashboard-user.html">
    <span class="brand-icon"><svg class="icon"><use href="#i-note"/></svg></span>
    <span class="brand-name">Poli<em>Music</em></span>
  </a>

  <nav class="mainnav" aria-label="Main navigation">
{nav}{manage}
  </nav>

  <form class="searchbox" action="search.html" method="get" role="search">
    <svg class="icon searchbox-icon"><use href="#i-search"/></svg>
    <input type="search" name="q" value="" placeholder="Search songs, artists, albums..." aria-label="Search songs, artists and albums">
  </form>

  <div class="userbox">
    <span class="userbox-hello">Welcome, <strong>{H(user)}</strong></span>
    {admin_badge}
    <a class="btn btn-outline btn-logout" href="login.html"><svg class="icon"><use href="#i-logout"/></svg> Log out</a>
  </div>
</header>"""


def player():
    return """
<!-- ============================ player ============================ -->
<div class="player" id="player">
  <div class="p-now">
    <span class="thumb thumb-player" id="pThumb">
      <img id="pThumbImg" alt="" hidden>
      <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
    </span>
    <span class="p-meta">
      <span class="p-title" id="pTitle">Nothing playing</span>
      <span class="p-sub" id="pSub">Pick a song from the list to start listening</span>
    </span>
  </div>

  <div class="p-controls">
    <div class="p-buttons">
      <button type="button" class="p-btn" id="pPrev" title="Previous song" aria-label="Previous song"><svg class="icon"><use href="#i-prev"/></svg></button>
      <button type="button" class="p-btn p-btn-main" id="pToggle" title="Play / Pause" aria-label="Play or pause">
        <svg class="icon p-icon-play" id="pIconPlay"><use href="#i-play"/></svg>
        <svg class="icon p-icon-pause" id="pIconPause" hidden><use href="#i-pause"/></svg>
      </button>
      <button type="button" class="p-btn" id="pNext" title="Next song" aria-label="Next song"><svg class="icon"><use href="#i-next"/></svg></button>
    </div>
    <div class="p-seek">
      <span class="p-time" id="pCur">0:00</span>
      <input type="range" id="pSeek" min="0" max="1000" value="0" step="1" aria-label="Seek">
      <span class="p-time" id="pDur">0:00</span>
    </div>
  </div>

  <div class="p-volume">
    <svg class="icon"><use href="#i-volume"/></svg>
    <input type="range" id="pVol" min="0" max="100" value="80" aria-label="Volume">
  </div>

  <audio id="audio" preload="metadata"></audio>
</div>"""


def add_modal():
    items = ""
    for pid in (1, 2):
        title, _, _, _, songs = PLAYLISTS[pid]
        items += f"""
        <form class="modal-item" method="post" action="#">
          <input type="hidden" name="action" value="add">
          <input type="hidden" name="playlist" value="{pid}">
          <input type="hidden" class="pl-song-input" name="song" value="">
          <button type="submit" class="modal-item-btn">
            <svg class="icon"><use href="#i-list"/></svg>
            <span class="modal-item-title">{H(title)}</span>
            <span class="modal-item-sub">{len(songs)} song(s)</span>
          </button>
        </form>"""
    return f"""
<!-- ===================== add-to-playlist modal ===================== -->
<div class="modal-backdrop" id="addModal" hidden>
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="addModalTitle">
    <div class="modal-head">
      <h3 id="addModalTitle">Add to playlist</h3>
      <button type="button" class="modal-close" id="addModalClose" title="Close" aria-label="Close"><svg class="icon"><use href="#i-close"/></svg></button>
    </div>
    <p class="modal-song" id="addModalSong"></p>
    <div class="modal-body" id="addModalBody">{items}
    </div>
  </div>
</div>

<div class="toasts" id="toasts" aria-live="polite"></div>
<script>window.PM_VROOT = "./";</script>"""


def footer():
    return """
<footer class="sitefoot">
  <p>PoliMusic &middot; a Classic ASP music app &middot; <a href="dashboard-user.html">Back to home</a></p>
</footer>"""


def song_table(songs, opts):
    """Mirror of includes/songs.asp SongTable()."""
    show_artist = True
    show_album = True
    html_out = ("<div class='table-wrap'><table class='song-table'><thead><tr>"
                "<th class='col-num' title='Track number'>#</th>"
                "<th class='col-title'>Title</th>")
    if show_artist:
        html_out += "<th class='col-artist'>Artist(s)</th>"
    if show_album:
        html_out += "<th class='col-album'>Album(s)</th>"
    html_out += ("<th class='col-plays' title='Times played'>Plays</th>"
                 "<th class='col-actions'>Actions</th></tr></thead><tbody>")

    if not songs:
        colspan = 5 + (1 if show_artist else 0) + (1 if show_album else 0)
        html_out += (f"<tr class='row-empty'><td colspan='{colspan}'>"
                     "No songs to show.</td></tr>")

    for i, s in enumerate(songs):
        html_out += (f"<tr data-idx='{i}'>"
                     f"<td class='col-num'>{i + 1}</td>"
                     f"<td class='col-title'><span class='cell-note'><svg class='icon'><use href='#i-note'/></svg></span><span class='song-name'>{H(s['name'])}</span></td>")
        if show_artist:
            html_out += f"<td class='col-artist'>{H(s['artists'])}</td>"
        if show_album:
            html_out += f"<td class='col-album'>{H(s['albums'])}</td>"
        html_out += f"<td class='col-plays'>{s['plays']}</td><td class='col-actions'>"
        html_out += (f"<button type='button' class='btn-play' data-idx='{i}' "
                     f"title='Play {H(s['name'])}' aria-label='Play {H(s['name'])}'>"
                     "<svg class='icon'><use href='#i-play'/></svg></button>")
        if "add" in opts:
            html_out += (f"<button type='button' class='btn-icon btn-add-pl' "
                         f"data-song='{s['id']}' data-name='{H(s['name'])}' "
                         f"title='Add {H(s['name'])} to a playlist' aria-label='Add to playlist'>"
                         "<svg class='icon'><use href='#i-plus'/></svg></button>")
        if "adminedit" in opts:
            html_out += (f"<a class='btn-icon' href='#' title='Edit song' aria-label='Edit song'>"
                         "<svg class='icon'><use href='#i-pencil'/></svg></a>")
        if "admindelete" in opts:
            html_out += (f"<form class='inline-form-del' method='post' action='#' "
                         f"onsubmit='return confirm(\"Delete the song {H(s['name'])}? This cannot be undone.\")'>"
                         "<input type='hidden' name='action' value='delete'>"
                         f"<input type='hidden' name='id' value='{s['id']}'>"
                         "<button type='submit' class='btn-icon btn-icon-danger' title='Delete song' aria-label='Delete song'>"
                         "<svg class='icon'><use href='#i-trash'/></svg></button></form>")
        if "remove:" in opts:
            pid = int(opts.split("remove:")[1])
            html_out += (f"<form class='inline-form-del' method='post' action='#' "
                         f"onsubmit='return confirm(\"Remove {H(s['name'])} from this playlist?\")'>"
                         "<input type='hidden' name='action' value='remove'>"
                         f"<input type='hidden' name='playlist' value='{pid}'>"
                         f"<input type='hidden' name='song' value='{s['id']}'>"
                         "<button type='submit' class='btn-icon btn-icon-danger' title='Remove from playlist' aria-label='Remove from playlist'>"
                         "<svg class='icon'><use href='#i-trash'/></svg></button></form>")
        html_out += "</td></tr>"
    html_out += "</tbody></table></div>"
    return html_out


def page(title, body, scripts=True):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - {H(title)}</title>
<link rel="icon" href="../images/favicon.ico">
<link rel="stylesheet" href="../css/styles.css">
</head>
<body>
{body}
{"<script src='../js/app.js'></script>" if scripts else ""}
</body>
</html>
"""


# ---------------------------------------------------------------- pages
def gen_login():
    body = """
<body class="auth-page">
<svg xmlns="http://www.w3.org/2000/svg" style="display:none" aria-hidden="true">
  <symbol id="i-note" viewBox="0 0 24 24"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></symbol>
</svg>

<main class="auth-wrap">
  <div class="auth-card">
    <a class="brand auth-brand" href="dashboard-user.html">
      <span class="brand-icon"><svg class="icon"><use href="#i-note"/></svg></span>
      <span class="brand-name">Poli<em>Music</em></span>
    </a>
    <h1 class="auth-title">Welcome back</h1>
    <p class="auth-sub">Sign in to browse the catalog and play your music.</p>

    <div class="alert alert-info">You have been logged out. See you soon!</div>

    <form method="post" action="#" autocomplete="on">
      <div class="field">
        <label for="username">Username</label>
        <input type="text" id="username" name="username" value="" required autofocus placeholder="your username">
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" required placeholder="your password">
      </div>
      <button type="submit" class="btn btn-primary btn-block">Sign in</button>
    </form>

    <div class="auth-hint">
      <strong>Demo accounts</strong>
      <span><code>userNormal</code> / <code>12345678</code> &mdash; normal user</span>
      <span><code>userAdmin</code> / <code>12345678</code> &mdash; administrator</span>
      <span><code>username1</code> / <code>12345678</code> &mdash; normal user</span>
    </div>
  </div>
</main>
</body>"""
    return page("Sign in", body, scripts=False)


def gen_dashboard(user, is_admin):
    songs = song_rows(sorted(SONGS.keys()))
    opts = "play,add,adminedit,admindelete" if is_admin else "play,add"
    n_pl = len(PLAYLISTS)
    hero_sub = ("Browse the music catalog, build your own playlists and enjoy the songs. "
                + ("As an administrator you can also manage songs, artists, albums and playlists."
                   if is_admin else ""))
    manage_btn = ('<a class="btn btn-purple btn-sm" href="#">Manage songs</a>'
                  if is_admin else "")
    body = topbar(user, is_admin) + player() + add_modal() + f"""
<main class="container">

  <!-- ==================== welcome / hero ==================== -->
  <section class="hero">
    <div>
      <h1 class="hero-title">Welcome, <span class="grad-text">{H(user)}</span>!</h1>
      <p class="hero-sub">{hero_sub}</p>
    </div>
    <div class="chips">
      <span class="badge {'badge-admin' if is_admin else 'badge-user'}">{'Administrator' if is_admin else 'User'}</span>
      <span class="chip chip-accent"><strong>{len(songs)}</strong> songs</span>
      <span class="chip"><strong>{len(ARTISTS)}</strong> artists</span>
      <span class="chip"><strong>{len(ALBUMS)}</strong> albums</span>
      <span class="chip chip-purple"><strong>{n_pl}</strong> playlists</span>
    </div>
  </section>

  <!-- ==================== tabs ==================== -->
  <nav class="tabs" aria-label="Catalog sections">
    <a class="tab active" href="#">Songs</a>
    <a class="tab" href="catalog-user.html">Artists</a>
    <a class="tab" href="catalog-user.html">Albums</a>
    <a class="tab" href="playlists-user.html">Playlists</a>
  </nav>

  <!-- ==================== songs ==================== -->
  <section class="panel" aria-labelledby="songsTitle">
    <div class="panel-head">
      <div>
        <h2 id="songsTitle">Song List</h2>
        <p class="panel-sub">Below you will find the complete list of songs available in the catalog. Press the <strong>Play</strong> button on any row to listen to it.</p>
      </div>
      <div class="pagerow">
        <button type="button" class="btn btn-outline btn-sm" onclick="PM.playIndex(0)">
          <svg class="icon"><use href="#i-play"/></svg> Start listening
        </button>
        {manage_btn}
      </div>
    </div>
    <script>window.PM_SONGS = {songs_json(songs)};</script>
    {song_table(songs, opts)}
  </section>

</main>
{footer()}"""
    return page("Home", body)


def gen_catalog():
    cards = ""
    for aid in sorted(ARTISTS):
        name, last, img = ARTISTS[aid]
        n = len(PLAYER_REV.get(aid, []))
        cards += f"""
      <a class="card" href="#">
        <span class="thumb">
          <img src="../ArtistImages/{img}" alt="" loading="lazy">
          <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
        </span>
        <span class="card-title">{H(name)} {H(last)}</span>
        <span class="card-sub">{n} song(s)</span>
      </a>"""
    body = topbar("userNormal", False) + player() + add_modal() + f"""
<main class="container">
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Artists</h2>
        <p class="panel-sub">All the artists in the catalog. Select one to see the songs they perform.</p>
      </div>
    </div>
    <div class="cards">{cards}
    </div>
  </section>
</main>
{footer()}"""
    return page("Artists", body)


def gen_playlists():
    cards = ""
    for pid in sorted(PLAYLISTS):
        title, date, ptype, img, songs = PLAYLISTS[pid]
        ptype_txt = "Private" if ptype == "1" else "Public"
        cards += f"""
      <a class="card" href="playlist-detail.html">
        <span class="thumb">
          <img src="../PlaylistImages/{img}" alt="" loading="lazy">
          <span class="thumb-note"><svg class="icon"><use href="#i-list"/></svg></span>
        </span>
        <span class="card-title">{H(title)}</span>
        <span class="card-sub">{len(songs)} song(s) &middot; {ptype_txt}</span>
      </a>"""
    body = topbar("userNormal", False) + player() + add_modal() + f"""
<main class="container">
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Your playlists</h2>
        <p class="panel-sub">Create your own playlists and fill them with the songs you like.</p>
      </div>
    </div>

    <form class="inline-form" method="post" action="#" style="margin-bottom:18px">
      <input type="hidden" name="action" value="create">
      <input type="text" name="title" maxlength="50" required placeholder="New playlist name" aria-label="New playlist name">
      <select name="type" aria-label="Playlist type"><option value="0">Public</option><option value="1">Private</option></select>
      <button type="submit" class="btn btn-primary">
        <svg class="icon"><use href="#i-plus"/></svg> Create playlist
      </button>
    </form>

    <div class="cards">{cards}
    </div>
  </section>
</main>
{footer()}"""
    return page("Playlists", body)


def gen_playlist_detail():
    pid = 2
    title, date, ptype, img, pl_songs = PLAYLISTS[pid]
    songs = song_rows(pl_songs)
    avail = song_rows([s for s in SONGS if s not in pl_songs])
    body = topbar("userNormal", False) + player() + add_modal() + f"""
<main class="container">

  <section class="detail-head">
    <span class="thumb">
      <img src="../PlaylistImages/{img}" alt="">
      <span class="thumb-note"><svg class="icon"><use href="#i-list"/></svg></span>
    </span>
    <div class="detail-meta">
      <h1>{H(title)}</h1>
      <div class="meta-line">
        <span>Playlist</span>
        <span class="meta-dot">by userNormal</span>
        <span class="meta-dot">{fmt_date(date)}</span>
        <span class="meta-dot">Public</span>
        <span class="meta-dot">{len(songs)} song(s)</span>
      </div>
      <div class="detail-actions">
        <button type="button" class="btn btn-primary" onclick="PM.playIndex(0)">
          <svg class="icon"><use href="#i-play"/></svg> Play playlist
        </button>
        <a class="btn btn-ghost" href="playlists-user.html">
          <svg class="icon"><use href="#i-prev"/></svg> All playlists
        </a>
        <form class="inline-form-del" method="post" action="#" onsubmit='return confirm("Delete this playlist and all the songs it contains? This cannot be undone.")'>
          <input type="hidden" name="action" value="delete">
          <input type="hidden" name="id" value="{pid}">
          <button type="submit" class="btn btn-danger btn-sm">
            <svg class="icon"><use href="#i-trash"/></svg> Delete playlist
          </button>
        </form>
      </div>
    </div>
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Songs in this playlist</h2>
        <p class="panel-sub">Press <strong>Play</strong> to listen. Use the trash icon to remove a song.</p>
      </div>
    </div>
    <script>window.PM_SONGS = {songs_json(songs)};</script>
    {song_table(songs, f"play,remove:{pid}")}
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Playlist details</h2>
        <p class="panel-sub">Rename the playlist or change its visibility (public / private).</p>
      </div>
    </div>
    <form method="post" action="#">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="id" value="{pid}">
      <div class="field-row">
        <div class="field">
          <label for="plTitle">Title</label>
          <input type="text" id="plTitle" name="title" maxlength="50" value="{H(title)}" required>
        </div>
        <div class="field" style="max-width:230px">
          <label for="plType">Type</label>
          <select id="plType" name="type"><option value="0">Public</option><option value="1">Private</option></select>
        </div>
      </div>
      <button type="submit" class="btn btn-primary btn-sm">Save changes</button>
    </form>
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Add songs</h2>
        <p class="panel-sub">Songs from the catalog that are not in this playlist yet.</p>
      </div>
    </div>
    <div class="table-wrap">
      <table class="song-table">
        <thead>
          <tr>
            <th class="col-num">#</th>
            <th class="col-title">Title</th>
            <th>Artist(s)</th>
            <th class="col-actions">Action</th>
          </tr>
        </thead>
        <tbody>
          {"".join(f'''
          <tr>
            <td class="col-num">{i2 + 1}</td>
            <td class="col-title"><span class="cell-note"><svg class="icon"><use href="#i-note"/></svg></span><span class="song-name">{H(s["name"])}</span></td>
            <td>{H(s["artists"])}</td>
            <td class="col-actions">
              <form class="inline-form-del" method="post" action="#">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="playlist" value="{pid}">
                <input type="hidden" name="song" value="{s["id"]}">
                <button type="submit" class="btn btn-outline btn-sm">
                  <svg class="icon"><use href="#i-plus"/></svg> Add
                </button>
              </form>
            </td>
          </tr>''' for i2, s in enumerate(avail))}
        </tbody>
      </table>
    </div>
  </section>

</main>
{footer()}"""
    return page(title, body)


def gen_search():
    q = "a"
    res_songs = song_rows([sid for sid, (n, _, _) in SONGS.items()
                           if q in n.lower()])
    res_artists = sorted([aid for aid, (n, l, _) in ARTISTS.items()
                          if q in (n + l).lower()])
    res_albums = sorted([aid for aid, (t, _, _) in ALBUMS.items()
                         if q in t.lower()])

    artist_cards = ""
    for aid in res_artists:
        name, last, img = ARTISTS[aid]
        n = len(PLAYER_REV.get(aid, []))
        artist_cards += f"""
      <a class="card" href="#">
        <span class="thumb">
          <img src="../ArtistImages/{img}" alt="" loading="lazy">
          <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
        </span>
        <span class="card-title">{H(name)} {H(last)}</span>
        <span class="card-sub">{n} song(s)</span>
      </a>"""
    album_cards = ""
    for aid in res_albums:
        t, y, img = ALBUMS[aid]
        n = len(TRACKLIST[aid])
        album_cards += f"""
      <a class="card" href="#">
        <span class="thumb">
          <img src="../albumImages/{img}" alt="" loading="lazy">
          <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
        </span>
        <span class="card-title">{H(t)}</span>
        <span class="card-sub">{n} track(s) &middot; {y}</span>
      </a>"""

    body = topbar("userNormal", False) + player() + add_modal() + f"""
<main class="container">

  <section class="panel">
    <div class="panel-head">
      <div>
        <h1 class="hero-title" style="font-size:24px">Search results for &quot;<span class="grad-text">{H(q)}</span>&quot;</h1>
        <p class="panel-sub">
          {len(res_songs)} song(s), {len(res_artists)} artist(s) and {len(res_albums)} album(s) match your search.
        </p>
      </div>
      <form class="inline-form" action="search.html" method="get" role="search">
        <input type="search" name="q" value="{H(q)}" placeholder="Search again..." aria-label="Search">
        <button type="submit" class="btn btn-primary btn-sm">
          <svg class="icon"><use href="#i-search"/></svg> Search
        </button>
      </form>
    </div>
  </section>

  <section class="panel" aria-labelledby="resSongs">
    <div class="panel-head">
      <div>
        <h2 id="resSongs">Songs</h2>
        <p class="panel-sub">{len(res_songs)} song(s) found. Press <strong>Play</strong> to listen.</p>
      </div>
    </div>
    <script>window.PM_SONGS = {songs_json(res_songs)};</script>
    {song_table(res_songs, "play,add")}
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Artists</h2>
        <p class="panel-sub">{len(res_artists)} artist(s) found.</p>
      </div>
    </div>
    <div class="cards">{artist_cards}
    </div>
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Albums</h2>
        <p class="panel-sub">{len(res_albums)} album(s) found.</p>
      </div>
    </div>
    <div class="cards">{album_cards}
    </div>
  </section>

</main>
{footer()}"""
    return page(f'Search "{q}"', body)


def gen_admin_songs():
    """admin/songs.asp - CRUD in edit mode (song #1) with create form open."""
    songs = song_rows(sorted(SONGS.keys()))
    checks = ""
    for aid in sorted(ARTISTS):
        name, last, _ = ARTISTS[aid]
        # song 1 is performed by artists 1 and 2
        checked = "checked" if aid in (1, 2) else ""
        checks += (f"\n          <label>\n"
                   f"            <input type=\"checkbox\" name=\"artists\" value=\"{aid}\" {checked}>\n"
                   f"            {H(name)} {H(last)}\n"
                   f"          </label>")
    create_checks = ""
    for aid in sorted(ARTISTS):
        name, last, _ = ARTISTS[aid]
        create_checks += (f"\n          <label>\n"
                          f"            <input type=\"checkbox\" name=\"artists\" value=\"{aid}\">\n"
                          f"            {H(name)} {H(last)}\n"
                          f"          </label>")
    body = topbar("userAdmin", True) + player() + add_modal() + f"""
<main class="container">

  <section class="panel-head">
    <div>
      <h1 class="hero-title" style="font-size:26px">Manage songs</h1>
      <p class="panel-sub">Create, edit and delete songs, and link them to their artists.</p>
    </div>
    <a class="btn btn-ghost btn-sm" href="dashboard-admin.html">
      <svg class="icon"><use href="#i-prev"/></svg> Back to song list
    </a>
  </section>

  <!-- ==================== edit song ==================== -->
  <section class="panel form-panel">
    <div class="panel-head">
      <div>
        <h2><svg class="icon"><use href="#i-pencil"/></svg> Edit song #1</h2>
      </div>
      <a class="btn btn-ghost btn-sm" href="#">Cancel</a>
    </div>
    <form method="post" action="#">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="id" value="1">
      <div class="field-row">
        <div class="field">
          <label for="eName">Song name</label>
          <input type="text" id="eName" name="name" maxlength="50" value="Adventure" required>
        </div>
        <div class="field">
          <label for="ePath">File path</label>
          <input type="text" id="ePath" name="path" maxlength="255" value="~/songFiles/bensound-adventure.mp3" required>
          <div class="hint">Path inside the app, e.g. <code>~/songFiles/bensound-adventure.mp3</code></div>
        </div>
        <div class="field" style="max-width:130px">
          <label for="ePlays">Plays</label>
          <input type="number" id="ePlays" name="plays" min="0" value="0">
        </div>
      </div>
      <div class="field">
        <label>Artists</label>
        <div class="checkgrid">{checks}
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Save changes</button>
    </form>
  </section>

  <!-- ==================== create song ==================== -->
  <details class="panel form-panel">
    <summary class="form-summary"><svg class="icon"><use href="#i-plus"/></svg> Create a new song</summary>
    <form method="post" action="#">
      <input type="hidden" name="action" value="create">
      <div class="field-row">
        <div class="field">
          <label for="cName">Song name</label>
          <input type="text" id="cName" name="name" maxlength="50" placeholder="e.g. Adventure" required>
        </div>
        <div class="field">
          <label for="cPath">File path</label>
          <input type="text" id="cPath" name="path" maxlength="255" placeholder="~/songFiles/bensound-adventure.mp3" required>
          <div class="hint">Path inside the app, e.g. <code>~/songFiles/bensound-adventure.mp3</code></div>
        </div>
        <div class="field" style="max-width:130px">
          <label for="cPlays">Plays</label>
          <input type="number" id="cPlays" name="plays" min="0" value="0">
        </div>
      </div>
      <div class="field">
        <label>Artists</label>
        <div class="checkgrid">{create_checks}
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Create song</button>
    </form>
  </details>

  <!-- ==================== song list ==================== -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>All songs</h2>
        <p class="panel-sub">Press <strong>Play</strong> to listen. Use the pencil to edit or the trash to delete.</p>
      </div>
    </div>
    <script>window.PM_SONGS = {songs_json(songs)};</script>
    {song_table(songs, "play,add,adminedit,admindelete")}
  </section>

</main>
{footer()}"""
    return page("Manage songs", body)


# reverse index: artist -> songs (for song counts)
PLAYER_REV = {}
for _s, _arts in PLAYER.items():
    for _a in _arts:
        PLAYER_REV.setdefault(_a, []).append(_s)


def main():
    os.makedirs(OUT, exist_ok=True)
    pages = {
        "login.html": gen_login(),
        "dashboard-user.html": gen_dashboard("userNormal", False),
        "dashboard-admin.html": gen_dashboard("userAdmin", True),
        "catalog-user.html": gen_catalog(),
        "playlists-user.html": gen_playlists(),
        "playlist-detail.html": gen_playlist_detail(),
        "search.html": gen_search(),
        "admin-songs.html": gen_admin_songs(),
    }
    for name, content in pages.items():
        with open(os.path.join(OUT, name), "w", encoding="utf-8") as fh:
            fh.write(content)
    print(f"Generated {len(pages)} preview pages in _preview/")
    for name in sorted(pages):
        print("  -", name)


if __name__ == "__main__":
    main()
