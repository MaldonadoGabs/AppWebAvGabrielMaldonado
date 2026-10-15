<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<!--#include file="includes/songs.asp"-->
<%
'=====================================================================
' playlist.asp - playlist detail and management.
'
' POST actions:
'   action=create  title, type                 -> create a playlist
'   action=update  id, title, type             -> rename / change type
'   action=delete  id                          -> delete a playlist
'   action=add     playlist, song              -> add a song
'   action=remove  playlist, song              -> remove a song
'
' GET: playlist.asp?id=N shows the playlist detail.
' Only the owner (or an admin) can manage a playlist.
'=====================================================================
RequireLogin

'--- only the owner or an admin can modify a playlist ---------------
Function CanManagePlaylist(pid)
    Dim rs
    CanManagePlaylist = False
    Set rs = Query("SELECT ID_USER FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ?", pid)
    If rs Is Nothing Then Exit Function
    If rs.EOF Then
        rs.Close
        Exit Function
    End If
    If CLng(rs("ID_USER")) = CurrentUserID() Or IsAdmin() Then CanManagePlaylist = True
    rs.Close
End Function

Sub SetFlash(ByVal msg)
    Session("PM_FLASH") = msg
End Sub

Dim action, pid, newTitle, newType, upTitle, upType, addSong, rmSong
Dim covers(4), ci

action = LCase(Request.Form("action") & "")

'--------------------------------------------------------------- create
If action = "create" Then
    newTitle = Trim(Request.Form("title") & "")
    newType = ToInt(Request.Form("type"))
    If Len(newTitle) > 0 Then
        covers(0) = "~/playlistImages/playlist1.png"
        covers(1) = "~/playlistImages/playlist2.png"
        covers(2) = "~/playlistImages/playlist3.png"
        covers(3) = "~/playlistImages/playlist4.png"
        covers(4) = "~/playlistImages/playlist5.png"
        Randomize
        ci = Int(Rnd() * 5)
        Query("INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) VALUES (?, ?, ?, ?, ?)", _
            CurrentUserID(), Left(newTitle, 50), Now(), newType, covers(ci))
        SetFlash "Playlist created: " & Left(newTitle, 50)
    End If
    Redirect VRoot() & "default.asp?tab=playlists"
End If

'--------------------------------------------------------------- update
If action = "update" Then
    pid = ToInt(Request.Form("id"))
    upTitle = Trim(Request.Form("title") & "")
    upType = ToInt(Request.Form("type"))
    If pid > 0 And CanManagePlaylist(pid) And Len(upTitle) > 0 Then
        Query("UPDATE TBL_PLAYLIST SET TITLE = ?, TYPE = ? WHERE ID_PLAYLIST = ?", Left(upTitle, 50), upType, pid)
        SetFlash "Playlist updated."
    End If
    If pid > 0 Then
        Redirect VRoot() & "playlist.asp?id=" & pid
    Else
        Redirect VRoot() & "default.asp?tab=playlists"
    End If
End If

'--------------------------------------------------------------- delete
If action = "delete" Then
    pid = ToInt(Request.Form("id"))
    If pid > 0 And CanManagePlaylist(pid) Then
        Query("DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ?", pid)
        Query("DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ?", pid)
        SetFlash "Playlist deleted."
    End If
    Redirect VRoot() & "default.asp?tab=playlists"
End If

'------------------------------------------------------------------ add
If action = "add" Then
    pid = ToInt(Request.Form("playlist"))
    addSong = ToInt(Request.Form("song"))
    If pid > 0 And addSong > 0 And CanManagePlaylist(pid) Then
        Query("INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) " & _
            "SELECT ?, ? WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?)", _
            pid, addSong, pid, addSong)
        SetFlash "Song added to the playlist."
    End If
    If pid > 0 Then
        Redirect VRoot() & "playlist.asp?id=" & pid
    Else
        Redirect VRoot() & "default.asp?tab=playlists"
    End If
End If

'---------------------------------------------------------------- remove
If action = "remove" Then
    pid = ToInt(Request.Form("playlist"))
    rmSong = ToInt(Request.Form("song"))
    If pid > 0 And rmSong > 0 And CanManagePlaylist(pid) Then
        Query("DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?", pid, rmSong)
        SetFlash "Song removed from the playlist."
    End If
    If pid > 0 Then
        Redirect VRoot() & "playlist.asp?id=" & pid
    Else
        Redirect VRoot() & "default.asp?tab=playlists"
    End If
End If

'=====================================================================
' VIEW
'=====================================================================
pid = ToInt(Request.QueryString("id"))
If pid <= 0 Then Redirect VRoot() & "default.asp?tab=playlists"

Dim rsPl, rsPlSongs, rsAvail, canManage, isPrivate, privateOnly, i2

Set rsPl = Query("SELECT pl.ID_PLAYLIST, pl.ID_USER, pl.TITLE, pl.CREATION_DATE, pl.TYPE, pl.PHOTO, u.USERNAME, " & _
    "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = pl.ID_PLAYLIST) AS SONG_COUNT " & _
    "FROM TBL_PLAYLIST pl JOIN TBL_USER u ON pl.ID_USER = u.ID_USER " & _
    "WHERE pl.ID_PLAYLIST = ?", pid)

If rsPl Is Nothing Or rsPl.EOF Then
    If Not rsPl Is Nothing Then rsPl.Close
    Redirect VRoot() & "default.asp?tab=playlists"
End If

canManage = CanManagePlaylist(pid)
isPrivate = (CLng(rsPl("TYPE")) = 1)
privateOnly = (isPrivate And Not canManage)

If Not privateOnly Then
    Set rsPlSongs = Query(SONG_COLS & " FROM TBL_PLAYLIST_SONG ps JOIN TBL_SONG s ON ps.ID_SONG = s.ID_SONG " & _
        "WHERE ps.ID_PLAYLIST = ? ORDER BY s.SONG_NAME", pid)
    LoadSongs rsPlSongs
    If canManage Then
        Set rsAvail = Query(SONG_COLS & " FROM TBL_SONG s " & _
            "WHERE s.ID_SONG NOT IN (SELECT ID_SONG FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ?) " & _
            "ORDER BY s.SONG_NAME", pid)
    End If
End If
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - <%= H(rsPl("TITLE") & "") %></title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <% If privateOnly Then %>
  <section class="panel">
    <div class="empty">
      <svg class="icon"><use href="#i-list"/></svg>
      <p>This playlist is private and belongs to another user.</p>
      <p><a class="btn btn-outline btn-sm" href="<%= VRoot() %>default.asp?tab=playlists">Back to playlists</a></p>
    </div>
  </section>
  <% Else %>

  <section class="detail-head">
    <span class="thumb">
      <img src="<%= MediaURL(rsPl("PHOTO") & "") %>" alt="">
      <span class="thumb-note"><svg class="icon"><use href="#i-list"/></svg></span>
    </span>
    <div class="detail-meta">
      <h1><%= H(rsPl("TITLE") & "") %></h1>
      <div class="meta-line">
        <span>Playlist</span>
        <span class="meta-dot">by <%= H(rsPl("USERNAME") & "") %></span>
        <span class="meta-dot"><%= FmtDate(rsPl("CREATION_DATE")) %></span>
        <span class="meta-dot"><%= H(CatalogText("2", rsPl("TYPE") & "")) %></span>
        <span class="meta-dot"><%= gSongCount %> song(s)</span>
      </div>
      <div class="detail-actions">
        <% If gSongCount > 0 Then %>
        <button type="button" class="btn btn-primary" onclick="PM.playIndex(0)">
          <svg class="icon"><use href="#i-play"/></svg> Play playlist
        </button>
        <% End If %>
        <a class="btn btn-ghost" href="<%= VRoot() %>default.asp?tab=playlists">
          <svg class="icon"><use href="#i-prev"/></svg> All playlists
        </a>
        <% If canManage Then %>
        <form class="inline-form-del" method="post" action="<%= VRoot() %>playlist.asp" onsubmit="return confirm(""Delete this playlist and all the songs it contains? This cannot be undone."")">
          <input type="hidden" name="action" value="delete">
          <input type="hidden" name="id" value="<%= pid %>">
          <button type="submit" class="btn btn-danger btn-sm">
            <svg class="icon"><use href="#i-trash"/></svg> Delete playlist
          </button>
        </form>
        <% End If %>
      </div>
    </div>
  </section>

  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Songs in this playlist</h2>
        <p class="panel-sub">Press <strong>Play</strong> to listen.<% If canManage Then %> Use the trash icon to remove a song.<% End If %></p>
      </div>
    </div>
    <script>window.PM_SONGS = <%= SongsJson() %>;</script>
    <%= SongTable(True, True, "play" & If(canManage, ",remove:" & pid, "")) %>
  </section>

  <% If canManage Then %>
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>Playlist details</h2>
        <p class="panel-sub">Rename the playlist or change its visibility (public / private).</p>
      </div>
    </div>
    <form method="post" action="<%= VRoot() %>playlist.asp">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="id" value="<%= pid %>">
      <div class="field-row">
        <div class="field">
          <label for="plTitle">Title</label>
          <input type="text" id="plTitle" name="title" maxlength="50" value="<%= H(rsPl("TITLE") & "") %>" required>
        </div>
        <div class="field" style="max-width:230px">
          <label for="plType">Type</label>
          <select id="plType" name="type"><%= CatalogOptions("2", rsPl("TYPE") & "") %></select>
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
    <% If rsAvail Is Nothing Or rsAvail.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-note"/></svg>
      <p>Every song in the catalog is already in this playlist.</p>
    </div>
    <% Else %>
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
          <%
          i2 = 0
          Do While Not rsAvail.EOF
            i2 = i2 + 1
          %>
          <tr>
            <td class="col-num"><%= i2 %></td>
            <td class="col-title"><span class="cell-note"><svg class="icon"><use href="#i-note"/></svg></span><span class="song-name"><%= H(rsAvail("SONG_NAME")) %></span></td>
            <td><%= H(XmlUnEsc(rsAvail("ARTISTS") & "")) %></td>
            <td class="col-actions">
              <form class="inline-form-del" method="post" action="<%= VRoot() %>playlist.asp">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="playlist" value="<%= pid %>">
                <input type="hidden" name="song" value="<%= rsAvail("ID_SONG") %>">
                <button type="submit" class="btn btn-outline btn-sm">
                  <svg class="icon"><use href="#i-plus"/></svg> Add
                </button>
              </form>
            </td>
          </tr>
          <%
            rsAvail.MoveNext
          Loop
          rsAvail.Close
          %>
        </tbody>
      </table>
    </div>
    <% End If %>
  </section>
  <% End If %>

  <% End If %>

</main>

<!--#include file="includes/footer.asp"-->
<script src="<%= VRoot() %>js/app.js"></script>
</body>
</html>
