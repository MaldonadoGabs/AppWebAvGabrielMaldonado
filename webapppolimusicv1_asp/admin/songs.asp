<%@ Language="VBScript" %>
<!--#include file="../includes/db.asp"-->
<!--#include file="../includes/songs.asp"-->
<%
'=====================================================================
' admin/songs.asp - song management (admin only).
' Create / edit / delete songs and link them to artists.
'=====================================================================
RequireAdmin

Dim action, songId, songName, songPath, songPlays, artistIds, errMsg
Dim editId, rsEdit, rsEditArtists, rsSongsList, rsArtistsAll
Dim newIdRs, newSongId, checkedArtists

action = LCase(Request.Form("action") & "")
errMsg = ""

'--- save the artist links of a song ---------------------------------
Sub SaveSongArtists(sid, ids)
    Dim arts, ai, aid2
    arts = Split(ids, ",")
    For ai = 0 To UBound(arts)
        aid2 = ToInt(Trim(arts(ai)))
        If aid2 > 0 Then
            Query("INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) VALUES (?, ?)", sid, aid2)
        End If
    Next
End Sub

'--------------------------------------------------------------- create
If action = "create" Then
    songName = Trim(Request.Form("name") & "")
    songPath = Trim(Request.Form("path") & "")
    songPlays = ToInt(Request.Form("plays"))
    artistIds = Request.Form("artists") & ""
    If Len(songName) = 0 Or Len(songPath) = 0 Then
        SetFlash "The song name and the file path are required."
    Else
        Query("INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (?, ?, ?)", Left(songName, 50), Left(songPath, 255), songPlays)
        Set newIdRs = Query("SELECT SCOPE_IDENTITY() AS id")
        If Not newIdRs Is Nothing Then
            If Not newIdRs.EOF Then
                newSongId = CLng(newIdRs("id"))
                SaveSongArtists newSongId, artistIds
                SetFlash "Song created: " & Left(songName, 50)
            End If
            newIdRs.Close
        End If
    End If
    Redirect VRoot() & "admin/songs.asp"
End If

'--------------------------------------------------------------- update
If action = "update" Then
    songId = ToInt(Request.Form("id"))
    songName = Trim(Request.Form("name") & "")
    songPath = Trim(Request.Form("path") & "")
    songPlays = ToInt(Request.Form("plays"))
    artistIds = Request.Form("artists") & ""
    If Len(songName) = 0 Or Len(songPath) = 0 Then
        SetFlash "The song name and the file path are required."
        Redirect VRoot() & "admin/songs.asp?edit=" & songId
    End If
    Query("UPDATE TBL_SONG SET SONG_NAME = ?, SONG_PATH = ?, PLAYS = ? WHERE ID_SONG = ?", Left(songName, 50), Left(songPath, 255), songPlays, songId)
    Query("DELETE FROM TBL_PLAYER WHERE ID_SONG = ?", songId)
    SaveSongArtists songId, artistIds
    SetFlash "Song updated: " & Left(songName, 50)
    Redirect VRoot() & "admin/songs.asp"
End If

'--------------------------------------------------------------- delete
If action = "delete" Then
    songId = ToInt(Request.Form("id"))
    If songId > 0 Then
        Query("DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = ?", songId)
        Query("DELETE FROM TBL_TRACKLIST WHERE ID_SONG = ?", songId)
        Query("DELETE FROM TBL_PLAYER WHERE ID_SONG = ?", songId)
        Query("DELETE FROM TBL_SONG WHERE ID_SONG = ?", songId)
        SetFlash "Song deleted."
    End If
    Redirect VRoot() & "admin/songs.asp"
End If

'--- load data for the view -----------------------------------------
Set rsSongsList = Query(SONG_COLS & " FROM TBL_SONG s ORDER BY s.SONG_NAME")
LoadSongs rsSongsList

Set rsArtistsAll = Query("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME FROM TBL_ARTIST ORDER BY ARTIST_NAME, ARTIST_LASTNAME")

editId = ToInt(Request.QueryString("edit"))
If editId > 0 Then
    Set rsEdit = Query("SELECT ID_SONG, SONG_NAME, SONG_PATH, PLAYS FROM TBL_SONG WHERE ID_SONG = ?", editId)
    If Not rsEdit Is Nothing Then
        If rsEdit.EOF Then
            rsEdit.Close
            Set rsEdit = Nothing
            editId = 0
        Else
            Set rsEditArtists = Query("SELECT ID_ARTIST FROM TBL_PLAYER WHERE ID_SONG = ?", editId)
            checkedArtists = ""
            If Not rsEditArtists Is Nothing Then
                Do While Not rsEditArtists.EOF
                    checkedArtists = checkedArtists & CStr(rsEditArtists("ID_ARTIST")) & ","
                    rsEditArtists.MoveNext
                Loop
                rsEditArtists.Close
            End If
        End If
    Else
        editId = 0
    End If
End If
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - Manage songs</title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="../includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <section class="panel-head">
    <div>
      <h1 class="hero-title" style="font-size:26px">Manage songs</h1>
      <p class="panel-sub">Create, edit and delete songs, and link them to their artists.</p>
    </div>
    <a class="btn btn-ghost btn-sm" href="<%= VRoot() %>default.asp?tab=songs">
      <svg class="icon"><use href="#i-prev"/></svg> Back to song list
    </a>
  </section>

  <% If editId > 0 And Not rsEdit Is Nothing Then %>
  <!-- ==================== edit song ==================== -->
  <section class="panel form-panel">
    <div class="panel-head">
      <div>
        <h2><svg class="icon"><use href="#i-pencil"/></svg> Edit song #<%= editId %></h2>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%= VRoot() %>admin/songs.asp">Cancel</a>
    </div>
    <form method="post" action="<%= VRoot() %>admin/songs.asp">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="id" value="<%= editId %>">
      <div class="field-row">
        <div class="field">
          <label for="eName">Song name</label>
          <input type="text" id="eName" name="name" maxlength="50" value="<%= H(rsEdit("SONG_NAME") & "") %>" required>
        </div>
        <div class="field">
          <label for="ePath">File path</label>
          <input type="text" id="ePath" name="path" maxlength="255" value="<%= H(rsEdit("SONG_PATH") & "") %>" required>
          <div class="hint">Path inside the app, e.g. <code>~/songFiles/bensound-adventure.mp3</code></div>
        </div>
        <div class="field" style="max-width:130px">
          <label for="ePlays">Plays</label>
          <input type="number" id="ePlays" name="plays" min="0" value="<%= rsEdit("PLAYS") %>">
        </div>
      </div>
      <div class="field">
        <label>Artists</label>
        <div class="checkgrid">
          <% If rsArtistsAll Is Nothing Or rsArtistsAll.EOF Then %>
          <span class="muted">No artists available.</span>
          <% Else %>
          <% Do While Not rsArtistsAll.EOF %>
          <label>
            <input type="checkbox" name="artists" value="<%= rsArtistsAll("ID_ARTIST") %>" <% If InStr("," & checkedArtists & ",", "," & CStr(rsArtistsAll("ID_ARTIST")) & ",") > 0 Then %>checked<% End If %>>
            <%= H(rsArtistsAll("ARTIST_NAME") & "") %><% If Len(rsArtistsAll("ARTIST_LASTNAME") & "") > 0 Then %> <%= H(rsArtistsAll("ARTIST_LASTNAME")) %><% End If %>
          </label>
          <% rsArtistsAll.MoveNext : Loop %>
          <% End If %>
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Save changes</button>
    </form>
  </section>
  <% End If %>

  <!-- ==================== create song ==================== -->
  <details class="panel form-panel" <% If editId = 0 Then %>open<% End If %>>
    <summary class="form-summary"><svg class="icon"><use href="#i-plus"/></svg> Create a new song</summary>
    <form method="post" action="<%= VRoot() %>admin/songs.asp">
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
        <div class="checkgrid">
          <% If rsArtistsAll Is Nothing Or rsArtistsAll.EOF Then %>
          <span class="muted">No artists available.</span>
          <% Else %>
          <% Do While Not rsArtistsAll.EOF %>
          <label>
            <input type="checkbox" name="artists" value="<%= rsArtistsAll("ID_ARTIST") %>">
            <%= H(rsArtistsAll("ARTIST_NAME") & "") %><% If Len(rsArtistsAll("ARTIST_LASTNAME") & "") > 0 Then %> <%= H(rsArtistsAll("ARTIST_LASTNAME")) %><% End If %>
          </label>
          <% rsArtistsAll.MoveNext : Loop %>
          <% End If %>
        </div>
        <div class="hint">Select one or more artists that perform this song.</div>
      </div>
      <button type="submit" class="btn btn-primary">Create song</button>
    </form>
  </details>

  <!-- ==================== song list ==================== -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>All songs</h2>
        <p class="panel-sub"><%= gSongCount %> song(s) in the catalog.</p>
      </div>
    </div>
    <script>window.PM_SONGS = <%= SongsJson() %>;</script>
    <%= SongTable(True, True, "play,adminedit,admindelete") %>
  </section>

</main>

<!--#include file="../includes/footer.asp"-->
<script src="<%= VRoot() %>js/app.js"></script>
</body>
</html>
