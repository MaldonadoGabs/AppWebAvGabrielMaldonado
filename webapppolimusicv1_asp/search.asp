<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<!--#include file="includes/songs.asp"-->
<%
'=====================================================================
' search.asp - search songs, artists and albums by keyword.
'=====================================================================
RequireLogin

Dim q
q = Trim(Request.QueryString("q") & "")

Dim rsSongs, rsArtists, rsAlbums
Dim nResSongs, nResArtists, nResAlbums
nResSongs = 0 : nResArtists = 0 : nResAlbums = 0

If Len(q) > 0 Then
    Dim like
    like = "%" & q & "%"

    Set rsSongs = Query(SONG_COLS & " FROM TBL_SONG s WHERE s.SONG_NAME LIKE ? ORDER BY s.SONG_NAME", like)
    LoadSongs rsSongs
    nResSongs = gSongCount

    Set rsArtists = Query("SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
        "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = a.ID_ARTIST) AS SONG_COUNT " & _
        "FROM TBL_ARTIST a WHERE a.ARTIST_NAME LIKE ? OR a.ARTIST_LASTNAME LIKE ? " & _
        "ORDER BY a.ARTIST_NAME, a.ARTIST_LASTNAME", like, like)

    Set rsAlbums = Query("SELECT al.ID_ALBUM, al.TITLE_ALBUM, al.RELEASE_YEAR, al.ALBUM_IMAGE_PATH, " & _
        "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = al.ID_ALBUM) AS TRACK_COUNT " & _
        "FROM TBL_ALBUM al WHERE al.TITLE_ALBUM LIKE ? ORDER BY al.TITLE_ALBUM", like)
End If
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - Search<% If Len(q) > 0 Then %> &quot;<%= H(q) %>&quot;<% End If %></title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h1 class="hero-title" style="font-size:24px">Search results<% If Len(q) > 0 Then %> for &quot;<span class="grad-text"><%= H(q) %></span>&quot;<% End If %></h1>
        <p class="panel-sub">
          <% If Len(q) = 0 Then %>
            Use the search box above to look for songs, artists and albums.
          <% Else %>
            <%= nResSongs %> song(s), <%= nResArtists %> artist(s) and <%= nResAlbums %> album(s) match your search.
          <% End If %>
        </p>
      </div>
      <form class="inline-form" action="<%= VRoot() %>search.asp" method="get" role="search">
        <input type="search" name="q" value="<%= H(q) %>" placeholder="Search again..." aria-label="Search">
        <button type="submit" class="btn btn-primary btn-sm">
          <svg class="icon"><use href="#i-search"/></svg> Search
        </button>
      </form>
    </div>

    <% If Len(q) = 0 Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-search"/></svg>
      <p>Type a keyword to start searching the catalog.</p>
    </div>
    <% End If %>
  </section>

  <% If Len(q) > 0 And nResSongs > 0 Then %>
  <!-- songs -->
  <section class="panel" aria-labelledby="resSongs">
    <div class="panel-head">
      <div>
        <h2 id="resSongs">Songs</h2>
        <p class="panel-sub"><%= nResSongs %> song(s) found. Press <strong>Play</strong> to listen.</p>
      </div>
    </div>
    <script>window.PM_SONGS = <%= SongsJson() %>;</script>
    <%= SongTable(True, True, "play,add") %>
  </section>
  <% End If %>

  <% If Len(q) > 0 And nResArtists > 0 Then %>
  <!-- artists -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Artists</h2>
        <p class="panel-sub"><%= nResArtists %> artist(s) found.</p>
      </div>
    </div>
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
    <% rsArtists.Close %>
  </section>
  <% End If %>

  <% If Len(q) > 0 And nResAlbums > 0 Then %>
  <!-- albums -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Albums</h2>
        <p class="panel-sub"><%= nResAlbums %> album(s) found.</p>
      </div>
    </div>
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
    <% rsAlbums.Close %>
  </section>
  <% End If %>

  <% If Len(q) > 0 And nResSongs = 0 And nResArtists = 0 And nResAlbums = 0 Then %>
  <section class="panel">
    <div class="empty">
      <svg class="icon"><use href="#i-search"/></svg>
      <p>No results for &quot;<%= H(q) %>&quot;. Try a different keyword.</p>
    </div>
  </section>
  <% End If %>

</main>

<!--#include file="includes/footer.asp"-->
<script src="<%= VRoot() %>js/app.js"></script>
</body>
</html>
