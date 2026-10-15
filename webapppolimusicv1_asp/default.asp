<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<!--#include file="includes/songs.asp"-->
<%
'=====================================================================
' default.asp - main dashboard.
' Shows the welcome message with the logged-in user's name, quick
' catalog stats and four tabs: songs (HTML table), artists, albums
' and playlists.
'=====================================================================
RequireLogin

Dim tab
tab = LCase(Request.QueryString("tab") & "")
If tab <> "artists" And tab <> "albums" And tab <> "playlists" Then tab = "songs"

' --- quick stats for the hero -------------------------------------
Dim nSongs, nArtists, nAlbums, nPlaylists, rsStat
nSongs = 0 : nArtists = 0 : nAlbums = 0 : nPlaylists = 0

Set rsStat = Query("SELECT COUNT(*) AS N FROM TBL_SONG")
If Not rsStat Is Nothing Then nSongs = rsStat("N") : rsStat.Close

Set rsStat = Query("SELECT COUNT(*) AS N FROM TBL_ARTIST")
If Not rsStat Is Nothing Then nArtists = rsStat("N") : rsStat.Close

Set rsStat = Query("SELECT COUNT(*) AS N FROM TBL_ALBUM")
If Not rsStat Is Nothing Then nAlbums = rsStat("N") : rsStat.Close

If IsAdmin() Then
    Set rsStat = Query("SELECT COUNT(*) AS N FROM TBL_PLAYLIST")
Else
    Set rsStat = Query("SELECT COUNT(*) AS N FROM TBL_PLAYLIST WHERE ID_USER = ?", CurrentUserID())
End If
If Not rsStat Is Nothing Then nPlaylists = rsStat("N") : rsStat.Close

' --- data for the active tab --------------------------------------
Dim rsSongs, rsArtists, rsAlbums, rsPl

If tab = "songs" Then
    Set rsSongs = Query(SONG_COLS & " FROM TBL_SONG s ORDER BY s.SONG_NAME")
    LoadSongs rsSongs
ElseIf tab = "artists" Then
    Set rsArtists = Query("SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
        "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = a.ID_ARTIST) AS SONG_COUNT " & _
        "FROM TBL_ARTIST a ORDER BY a.ARTIST_NAME, a.ARTIST_LASTNAME")
ElseIf tab = "albums" Then
    Set rsAlbums = Query("SELECT al.ID_ALBUM, al.TITLE_ALBUM, al.RELEASE_YEAR, al.ALBUM_IMAGE_PATH, " & _
        "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = al.ID_ALBUM) AS TRACK_COUNT " & _
        "FROM TBL_ALBUM al ORDER BY al.TITLE_ALBUM")
Else
    If IsAdmin() Then
        Set rsPl = Query("SELECT pl.ID_PLAYLIST, pl.TITLE, pl.CREATION_DATE, pl.TYPE, pl.PHOTO, u.USERNAME, " & _
            "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = pl.ID_PLAYLIST) AS SONG_COUNT " & _
            "FROM TBL_PLAYLIST pl JOIN TBL_USER u ON pl.ID_USER = u.ID_USER " & _
            "ORDER BY pl.CREATION_DATE DESC, pl.ID_PLAYLIST DESC")
    Else
        Set rsPl = Query("SELECT pl.ID_PLAYLIST, pl.TITLE, pl.CREATION_DATE, pl.TYPE, pl.PHOTO, u.USERNAME, " & _
            "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = pl.ID_PLAYLIST) AS SONG_COUNT " & _
            "FROM TBL_PLAYLIST pl JOIN TBL_USER u ON pl.ID_USER = u.ID_USER " & _
            "WHERE pl.ID_USER = ? ORDER BY pl.CREATION_DATE DESC, pl.ID_PLAYLIST DESC", CurrentUserID())
    End If
End If
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - Home</title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <!-- ==================== welcome / hero ==================== -->
  <section class="hero">
    <div>
      <h1 class="hero-title">Welcome, <span class="grad-text"><%= H(Session("USER_NAME")) %></span>!</h1>
      <p class="hero-sub">Browse the music catalog, build your own playlists and enjoy the songs. <% If IsAdmin() Then %>As an administrator you can also manage songs, artists, albums and playlists.<% End If %></p>
    </div>
    <div class="chips">
      <span class="badge <% If IsAdmin() Then %>badge-admin<% Else %>badge-user<% End If %>"><% If IsAdmin() Then %>Administrator<% Else %>User<% End If %></span>
      <span class="chip chip-accent"><strong><%= nSongs %></strong> songs</span>
      <span class="chip"><strong><%= nArtists %></strong> artists</span>
      <span class="chip"><strong><%= nAlbums %></strong> albums</span>
      <span class="chip chip-purple"><strong><%= nPlaylists %></strong> playlists</span>
    </div>
  </section>

  <!-- ==================== tabs ==================== -->
  <nav class="tabs" aria-label="Catalog sections">
    <a class="tab <% If tab = "songs" Then %>active<% End If %>" href="default.asp?tab=songs">Songs</a>
    <a class="tab <% If tab = "artists" Then %>active<% End If %>" href="default.asp?tab=artists">Artists</a>
    <a class="tab <% If tab = "albums" Then %>active<% End If %>" href="default.asp?tab=albums">Albums</a>
    <a class="tab <% If tab = "playlists" Then %>active<% End If %>" href="default.asp?tab=playlists">Playlists</a>
  </nav>

  <% If tab = "songs" Then %>
  <!-- ==================== songs ==================== -->
  <section class="panel" aria-labelledby="songsTitle">
    <div class="panel-head">
      <div>
        <h2 id="songsTitle">Song List</h2>
        <p class="panel-sub">Below you will find the complete list of songs available in the catalog. Press the <strong>Play</strong> button on any row to listen to it.</p>
      </div>
      <div class="pagerow">
        <% If gSongCount > 0 Then %>
        <button type="button" class="btn btn-outline btn-sm" onclick="PM.playIndex(0)">
          <svg class="icon"><use href="#i-play"/></svg> Start listening
        </button>
        <% End If %>
        <% If IsAdmin() Then %>
        <a class="btn btn-purple btn-sm" href="<%= VRoot() %>admin/songs.asp">Manage songs</a>
        <% End If %>
      </div>
    </div>
    <script>window.PM_SONGS = <%= SongsJson() %>;</script>
    <%= SongTable(True, True, "play,add" & If(IsAdmin(), ",adminedit,admindelete", "")) %>
  </section>

  <% ElseIf tab = "artists" Then %>
  <!-- ==================== artists ==================== -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Artists</h2>
        <p class="panel-sub">All the artists in the catalog. Select one to see the songs they perform.</p>
      </div>
      <% If IsAdmin() Then %>
      <a class="btn btn-purple btn-sm" href="<%= VRoot() %>admin/artists.asp">Manage artists</a>
      <% End If %>
    </div>
    <% If rsArtists Is Nothing Or rsArtists.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-user"/></svg>
      <p>There are no artists in the catalog yet.</p>
    </div>
    <% Else %>
    <div class="cards">
      <% Do While Not rsArtists.EOF %>
      <a class="card" href="<%= VRoot() %>artist.asp?id=<%= rsArtists("ID_ARTIST") %>">
        <span class="thumb">
          <img src="<%= MediaURL(rsArtists("ARTIST_IMAGE") & "") %>" alt="" loading="lazy">
          <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
        </span>
        <span class="card-title"><%= H(rsArtists("ARTIST_NAME") & "") %><% If Len(rsArtists("ARTIST_LASTNAME") & "") > 0 Then %> <%= H(rsArtists("ARTIST_LASTNAME")) %><% End If %></span>
        <span class="card-sub"><%= rsArtists("SONG_COUNT") %> song(s)</span>
      </a>
      <% rsArtists.MoveNext : Loop %>
    </div>
    <% End If %>
    <% If Not rsArtists Is Nothing Then rsArtists.Close %>
  </section>

  <% ElseIf tab = "albums" Then %>
  <!-- ==================== albums ==================== -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Albums</h2>
        <p class="panel-sub">Every album in the catalog. Select one to see its track list.</p>
      </div>
      <% If IsAdmin() Then %>
      <a class="btn btn-purple btn-sm" href="<%= VRoot() %>admin/albums.asp">Manage albums</a>
      <% End If %>
    </div>
    <% If rsAlbums Is Nothing Or rsAlbums.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-list"/></svg>
      <p>There are no albums in the catalog yet.</p>
    </div>
    <% Else %>
    <div class="cards">
      <% Do While Not rsAlbums.EOF %>
      <a class="card" href="<%= VRoot() %>album.asp?id=<%= rsAlbums("ID_ALBUM") %>">
        <span class="thumb">
          <img src="<%= MediaURL(rsAlbums("ALBUM_IMAGE_PATH") & "") %>" alt="" loading="lazy">
          <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
        </span>
        <span class="card-title"><%= H(rsAlbums("TITLE_ALBUM") & "") %></span>
        <span class="card-sub"><%= rsAlbums("TRACK_COUNT") %> track(s)<% If Not IsNull(rsAlbums("RELEASE_YEAR")) Then %> &middot; <%= rsAlbums("RELEASE_YEAR") %><% End If %></span>
      </a>
      <% rsAlbums.MoveNext : Loop %>
    </div>
    <% End If %>
    <% If Not rsAlbums Is Nothing Then rsAlbums.Close %>
  </section>

  <% Else %>
  <!-- ==================== playlists ==================== -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2><% If IsAdmin() Then %>All playlists<% Else %>Your playlists<% End If %></h2>
        <p class="panel-sub"><% If IsAdmin() Then %>Playlists created by every user. You can edit or delete any of them.<% Else %>Create your own playlists and fill them with the songs you like.<% End If %></p>
      </div>
    </div>

    <form class="inline-form" method="post" action="<%= VRoot() %>playlist.asp" style="margin-bottom:18px">
      <input type="hidden" name="action" value="create">
      <input type="text" name="title" maxlength="50" required placeholder="New playlist name" aria-label="New playlist name">
      <select name="type" aria-label="Playlist type"><%= CatalogOptions("2", "0") %></select>
      <button type="submit" class="btn btn-primary">
        <svg class="icon"><use href="#i-plus"/></svg> Create playlist
      </button>
    </form>

    <% If rsPl Is Nothing Or rsPl.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-list"/></svg>
      <p><% If IsAdmin() Then %>No playlists have been created yet.<% Else %>You do not have any playlists yet. Create your first one using the form above.<% End If %></p>
    </div>
    <% Else %>
    <div class="cards">
      <% Do While Not rsPl.EOF %>
      <a class="card" href="<%= VRoot() %>playlist.asp?id=<%= rsPl("ID_PLAYLIST") %>">
        <span class="thumb">
          <img src="<%= MediaURL(rsPl("PHOTO") & "") %>" alt="" loading="lazy">
          <span class="thumb-note"><svg class="icon"><use href="#i-list"/></svg></span>
        </span>
        <span class="card-title"><%= H(rsPl("TITLE") & "") %></span>
        <span class="card-sub"><%= rsPl("SONG_COUNT") %> song(s) &middot; <%= H(CatalogText("2", rsPl("TYPE") & "")) %><% If IsAdmin() Then %> &middot; by <%= H(rsPl("USERNAME") & "") %><% End If %></span>
      </a>
      <% rsPl.MoveNext : Loop %>
    </div>
    <% End If %>
    <% If Not rsPl Is Nothing Then rsPl.Close %>
  </section>
  <% End If %>

</main>

<!--#include file="includes/footer.asp"-->
<script src="<%= VRoot() %>js/app.js"></script>
</body>
</html>
