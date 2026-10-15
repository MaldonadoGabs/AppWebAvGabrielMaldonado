<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<!--#include file="includes/songs.asp"-->
<%
'=====================================================================
' artist.asp - artist detail page with the list of songs they perform.
'=====================================================================
RequireLogin

Dim aid
aid = ToInt(Request.QueryString("id"))
If aid <= 0 Then Redirect VRoot() & "default.asp?tab=artists"

Dim rsArtist
Set rsArtist = Query("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = ?", aid)

If rsArtist Is Nothing Or rsArtist.EOF Then
    If Not rsArtist Is Nothing Then rsArtist.Close
    Response.Redirect VRoot() & "default.asp?tab=artists"
    Response.End
End If

Dim rsArtistSongs
Set rsArtistSongs = Query(SONG_COLS & " FROM TBL_SONG s JOIN TBL_PLAYER p ON s.ID_SONG = p.ID_SONG " & _
    "WHERE p.ID_ARTIST = ? ORDER BY s.SONG_NAME", aid)
LoadSongs rsArtistSongs

Dim artistFullName
artistFullName = CStr(rsArtist("ARTIST_NAME"))
If Len(CStr(rsArtist("ARTIST_LASTNAME") & "")) > 0 Then artistFullName = artistFullName & " " & CStr(rsArtist("ARTIST_LASTNAME"))
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - <%= H(artistFullName) %></title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <section class="detail-head">
    <span class="thumb">
      <img src="<%= MediaURL(rsArtist("ARTIST_IMAGE") & "") %>" alt="">
      <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
    </span>
    <div class="detail-meta">
      <h1><%= H(artistFullName) %></h1>
      <div class="meta-line">
        <span>Artist</span>
        <span class="meta-dot"><%= gSongCount %> song(s) in the catalog</span>
      </div>
      <div class="detail-actions">
        <% If gSongCount > 0 Then %>
        <button type="button" class="btn btn-primary" onclick="PM.playIndex(0)">
          <svg class="icon"><use href="#i-play"/></svg> Play songs
        </button>
        <% End If %>
        <a class="btn btn-ghost" href="<%= VRoot() %>default.asp?tab=artists">
          <svg class="icon"><use href="#i-prev"/></svg> All artists
        </a>
        <% If IsAdmin() Then %>
        <a class="btn btn-purple btn-sm" href="<%= VRoot() %>admin/artists.asp?edit=<%= aid %>">
          <svg class="icon"><use href="#i-pencil"/></svg> Edit artist
        </a>
        <% End If %>
      </div>
    </div>
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Songs by <%= H(artistFullName) %></h2>
        <p class="panel-sub">Every song performed by this artist. Press <strong>Play</strong> to listen.</p>
      </div>
    </div>
    <script>window.PM_SONGS = <%= SongsJson() %>;</script>
    <%= SongTable(True, True, "play,add") %>
  </section>

</main>

<!--#include file="includes/footer.asp"-->
<script src="<%= VRoot() %>js/app.js"></script>
</body>
</html>
