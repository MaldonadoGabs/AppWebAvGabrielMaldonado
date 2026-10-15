<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<!--#include file="includes/songs.asp"-->
<%
'=====================================================================
' album.asp - album detail page with its track list.
'=====================================================================
RequireLogin

Dim aid
aid = ToInt(Request.QueryString("id"))
If aid <= 0 Then Redirect VRoot() & "default.asp?tab=albums"

Dim rsAlbum
Set rsAlbum = Query("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = ?", aid)

If rsAlbum Is Nothing Or rsAlbum.EOF Then
    If Not rsAlbum Is Nothing Then rsAlbum.Close
    Response.Redirect VRoot() & "default.asp?tab=albums"
    Response.End
End If

Dim rsAlbumSongs
Set rsAlbumSongs = Query(SONG_COLS & " FROM TBL_SONG s JOIN TBL_TRACKLIST t ON s.ID_SONG = t.ID_SONG " & _
    "WHERE t.ID_ALBUM = ? ORDER BY s.SONG_NAME", aid)
LoadSongs rsAlbumSongs
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - <%= H(rsAlbum("TITLE_ALBUM") & "") %></title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <section class="detail-head">
    <span class="thumb">
      <img src="<%= MediaURL(rsAlbum("ALBUM_IMAGE_PATH") & "") %>" alt="">
      <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
    </span>
    <div class="detail-meta">
      <h1><%= H(rsAlbum("TITLE_ALBUM") & "") %></h1>
      <div class="meta-line">
        <span>Album</span>
        <% If Not IsNull(rsAlbum("RELEASE_YEAR")) Then %><span class="meta-dot"><%= rsAlbum("RELEASE_YEAR") %></span><% End If %>
        <span class="meta-dot"><%= gSongCount %> track(s)</span>
      </div>
      <div class="detail-actions">
        <% If gSongCount > 0 Then %>
        <button type="button" class="btn btn-primary" onclick="PM.playIndex(0)">
          <svg class="icon"><use href="#i-play"/></svg> Play album
        </button>
        <% End If %>
        <a class="btn btn-ghost" href="<%= VRoot() %>default.asp?tab=albums">
          <svg class="icon"><use href="#i-prev"/></svg> All albums
        </a>
        <% If IsAdmin() Then %>
        <a class="btn btn-purple btn-sm" href="<%= VRoot() %>admin/albums.asp?edit=<%= aid %>">
          <svg class="icon"><use href="#i-pencil"/></svg> Edit album
        </a>
        <% End If %>
      </div>
    </div>
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Track list</h2>
        <p class="panel-sub">All the songs included in this album. Press <strong>Play</strong> to listen.</p>
      </div>
    </div>
    <script>window.PM_SONGS = <%= SongsJson() %>;</script>
    <%= SongTable(True, False, "play,add") %>
  </section>

</main>

<!--#include file="includes/footer.asp"-->
<script src="<%= VRoot() %>js/app.js"></script>
</body>
</html>
