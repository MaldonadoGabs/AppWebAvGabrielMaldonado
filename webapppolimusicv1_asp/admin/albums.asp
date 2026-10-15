<%@ Language="VBScript" %>
<!--#include file="../includes/db.asp"-->
<!--#include file="../includes/songs.asp"-->
<%
'=====================================================================
' admin/albums.asp - album management (admin only).
' Create / edit / delete albums and manage their track lists.
'=====================================================================
RequireAdmin

Dim action, albumId, albumTitle, albumYear, albumImage
Dim editId, rsEdit, rsList, rsTracks, rsAvail, rsCount, nList

action = LCase(Request.Form("action") & "")

'--------------------------------------------------------------- create
If action = "create" Then
    albumTitle = Trim(Request.Form("title") & "")
    albumYear = Trim(Request.Form("year") & "")
    albumImage = Trim(Request.Form("image") & "")
    If Len(albumTitle) = 0 Then
        SetFlash "The album title is required."
    Else
        If IsNumeric(albumYear) Then
            Query("INSERT INTO TBL_ALBUM (TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH) VALUES (?, ?, ?)", _
                Left(albumTitle, 50), CLng(albumYear), Left(albumImage, 255))
        Else
            Query("INSERT INTO TBL_ALBUM (TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH) VALUES (?, NULL, ?)", _
                Left(albumTitle, 50), Left(albumImage, 255))
        End If
        SetFlash "Album created: " & Left(albumTitle, 50)
    End If
    Redirect VRoot() & "admin/albums.asp"
End If

'--------------------------------------------------------------- update
If action = "update" Then
    albumId = ToInt(Request.Form("id"))
    albumTitle = Trim(Request.Form("title") & "")
    albumYear = Trim(Request.Form("year") & "")
    albumImage = Trim(Request.Form("image") & "")
    If Len(albumTitle) = 0 Then
        SetFlash "The album title is required."
        Redirect VRoot() & "admin/albums.asp?edit=" & albumId
    End If
    If IsNumeric(albumYear) Then
        Query("UPDATE TBL_ALBUM SET TITLE_ALBUM = ?, RELEASE_YEAR = ?, ALBUM_IMAGE_PATH = ? WHERE ID_ALBUM = ?", _
            Left(albumTitle, 50), CLng(albumYear), Left(albumImage, 255), albumId)
    Else
        Query("UPDATE TBL_ALBUM SET TITLE_ALBUM = ?, RELEASE_YEAR = NULL, ALBUM_IMAGE_PATH = ? WHERE ID_ALBUM = ?", _
            Left(albumTitle, 50), Left(albumImage, 255), albumId)
    End If
    SetFlash "Album updated: " & Left(albumTitle, 50)
    Redirect VRoot() & "admin/albums.asp"
End If

'--------------------------------------------------------------- delete
If action = "delete" Then
    albumId = ToInt(Request.Form("id"))
    If albumId > 0 Then
        Query("DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = ?", albumId)
        Query("DELETE FROM TBL_ALBUM WHERE ID_ALBUM = ?", albumId)
        SetFlash "Album deleted."
    End If
    Redirect VRoot() & "admin/albums.asp"
End If

'------------------------------------------------------------ add track
If action = "addtrack" Then
    albumId = ToInt(Request.Form("album"))
    Dim addSongId
    addSongId = ToInt(Request.Form("song"))
    If albumId > 0 And addSongId > 0 Then
        Query("INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) " & _
            "SELECT ?, ? WHERE NOT EXISTS (SELECT 1 FROM TBL_TRACKLIST WHERE ID_ALBUM = ? AND ID_SONG = ?)", _
            albumId, addSongId, albumId, addSongId)
        SetFlash "Song added to the album."
    End If
    Redirect VRoot() & "admin/albums.asp?edit=" & albumId
End If

'--------------------------------------------------------- remove track
If action = "removetrack" Then
    albumId = ToInt(Request.Form("album"))
    Dim rmSongId
    rmSongId = ToInt(Request.Form("song"))
    If albumId > 0 And rmSongId > 0 Then
        Query("DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = ? AND ID_SONG = ?", albumId, rmSongId)
        SetFlash "Song removed from the album."
    End If
    Redirect VRoot() & "admin/albums.asp?edit=" & albumId
End If

'--- load data for the view -----------------------------------------
Set rsList = Query("SELECT al.ID_ALBUM, al.TITLE_ALBUM, al.RELEASE_YEAR, al.ALBUM_IMAGE_PATH, " & _
    "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = al.ID_ALBUM) AS TRACK_COUNT " & _
    "FROM TBL_ALBUM al ORDER BY al.TITLE_ALBUM")

Set rsCount = Query("SELECT COUNT(*) AS N FROM TBL_ALBUM")
If rsCount Is Nothing Then
    nList = 0
Else
    nList = rsCount("N")
    rsCount.Close
End If

editId = ToInt(Request.QueryString("edit"))
If editId > 0 Then
    Set rsEdit = Query("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = ?", editId)
    If Not rsEdit Is Nothing Then
        If rsEdit.EOF Then
            rsEdit.Close
            Set rsEdit = Nothing
            editId = 0
        Else
            Set rsTracks = Query(SONG_COLS & " FROM TBL_TRACKLIST t JOIN TBL_SONG s ON t.ID_SONG = s.ID_SONG " & _
                "WHERE t.ID_ALBUM = ? ORDER BY s.SONG_NAME", editId)
            Set rsAvail = Query(SONG_COLS & " FROM TBL_SONG s " & _
                "WHERE s.ID_SONG NOT IN (SELECT ID_SONG FROM TBL_TRACKLIST WHERE ID_ALBUM = ?) " & _
                "ORDER BY s.SONG_NAME", editId)
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
<title>PoliMusic - Manage albums</title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="../includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <section class="panel-head">
    <div>
      <h1 class="hero-title" style="font-size:26px">Manage albums</h1>
      <p class="panel-sub">Create, edit and delete albums, and manage their track lists.</p>
    </div>
    <a class="btn btn-ghost btn-sm" href="<%= VRoot() %>default.asp?tab=albums">
      <svg class="icon"><use href="#i-prev"/></svg> Back to albums
    </a>
  </section>

  <% If editId > 0 And Not rsEdit Is Nothing Then %>
  <!-- ==================== edit album ==================== -->
  <section class="panel form-panel">
    <div class="panel-head">
      <div>
        <h2><svg class="icon"><use href="#i-pencil"/></svg> Edit album #<%= editId %></h2>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%= VRoot() %>admin/albums.asp">Cancel</a>
    </div>
    <form method="post" action="<%= VRoot() %>admin/albums.asp">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="id" value="<%= editId %>">
      <div class="field-row">
        <div class="field">
          <label for="eTitle">Album title</label>
          <input type="text" id="eTitle" name="title" maxlength="50" value="<%= H(rsEdit("TITLE_ALBUM") & "") %>" required>
        </div>
        <div class="field" style="max-width:150px">
          <label for="eYear">Release year</label>
          <input type="number" id="eYear" name="year" min="1900" max="2100" value="<% If Not IsNull(rsEdit("RELEASE_YEAR")) Then %><%= rsEdit("RELEASE_YEAR") %><% End If %>">
        </div>
        <div class="field">
          <label for="eImage">Image path</label>
          <input type="text" id="eImage" name="image" maxlength="255" value="<%= H(rsEdit("ALBUM_IMAGE_PATH") & "") %>">
          <div class="hint">Path inside the app, e.g. <code>~/albumImages/album1.png</code></div>
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Save changes</button>
    </form>

    <!-- track list management -->
    <h3 class="section-title" id="tracks">Track list</h3>
    <% If rsTracks Is Nothing Or rsTracks.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-note"/></svg>
      <p>This album has no songs yet. Add some below.</p>
    </div>
    <% Else %>
    <div class="table-wrap">
      <table class="song-table">
        <thead>
          <tr>
            <th class="col-num">#</th>
            <th>Title</th>
            <th>Artist(s)</th>
            <th class="col-actions">Action</th>
          </tr>
        </thead>
        <tbody>
          <%
          Dim i, tid, tname
          i = 0
          Do While Not rsTracks.EOF
            i = i + 1
            tid = rsTracks("ID_SONG")
            tname = rsTracks("SONG_NAME")
          %>
          <tr>
            <td class="col-num"><%= i %></td>
            <td class="col-title"><span class="cell-note"><svg class="icon"><use href="#i-note"/></svg></span><span class="song-name"><%= H(tname) %></span></td>
            <td><%= H(XmlUnEsc(rsTracks("ARTISTS") & "")) %></td>
            <td class="col-actions">
              <form class="inline-form-del" method="post" action="<%= VRoot() %>admin/albums.asp" onsubmit="return confirm(""Remove " & H(tname) & " from this album?"")">
                <input type="hidden" name="action" value="removetrack">
                <input type="hidden" name="album" value="<%= editId %>">
                <input type="hidden" name="song" value="<%= tid %>">
                <button type="submit" class="btn-icon btn-icon-danger" title="Remove from album"><svg class="icon"><use href="#i-trash"/></svg></button>
              </form>
            </td>
          </tr>
          <%
            rsTracks.MoveNext
          Loop
          rsTracks.Close
          %>
        </tbody>
      </table>
    </div>
    <% End If %>

    <h3 class="section-title">Add songs to this album</h3>
    <% If rsAvail Is Nothing Or rsAvail.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-list"/></svg>
      <p>Every song in the catalog is already in this album.</p>
    </div>
    <% Else %>
    <form class="inline-form" method="post" action="<%= VRoot() %>admin/albums.asp">
      <input type="hidden" name="action" value="addtrack">
      <input type="hidden" name="album" value="<%= editId %>">
      <select name="song" aria-label="Song to add" style="min-width:280px">
        <% Do While Not rsAvail.EOF %>
        <option value="<%= rsAvail("ID_SONG") %>"><%= H(rsAvail("SONG_NAME")) %><% If Len(XmlUnEsc(rsAvail("ARTISTS") & "")) > 0 Then %> - <%= H(XmlUnEsc(rsAvail("ARTISTS"))) %><% End If %></option>
        <% rsAvail.MoveNext : Loop %>
      </select>
      <button type="submit" class="btn btn-outline">
        <svg class="icon"><use href="#i-plus"/></svg> Add to album
      </button>
    </form>
    <% rsAvail.Close %>
    <% End If %>
  </section>
  <% End If %>

  <!-- ==================== create album ==================== -->
  <details class="panel form-panel" <% If editId = 0 Then %>open<% End If %>>
    <summary class="form-summary"><svg class="icon"><use href="#i-plus"/></svg> Create a new album</summary>
    <form method="post" action="<%= VRoot() %>admin/albums.asp">
      <input type="hidden" name="action" value="create">
      <div class="field-row">
        <div class="field">
          <label for="cTitle">Album title</label>
          <input type="text" id="cTitle" name="title" maxlength="50" placeholder="e.g. Rock Album" required>
        </div>
        <div class="field" style="max-width:150px">
          <label for="cYear">Release year</label>
          <input type="number" id="cYear" name="year" min="1900" max="2100" placeholder="e.g. 1976">
        </div>
        <div class="field">
          <label for="cImage">Image path</label>
          <input type="text" id="cImage" name="image" maxlength="255" placeholder="~/albumImages/album1.png">
          <div class="hint">Path inside the app, e.g. <code>~/albumImages/album1.png</code></div>
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Create album</button>
    </form>
  </details>

  <!-- ==================== album list ==================== -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>All albums</h2>
        <p class="panel-sub"><%= nList %> album(s) in the catalog.</p>
      </div>
    </div>
    <% If rsList Is Nothing Or rsList.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-list"/></svg>
      <p>There are no albums yet. Create the first one using the form above.</p>
    </div>
    <% Else %>
    <div class="table-wrap">
      <table class="song-table">
        <thead>
          <tr>
            <th class="col-num">#</th>
            <th>Album</th>
            <th>Image path</th>
            <th class="col-plays">Year</th>
            <th class="col-plays">Tracks</th>
            <th class="col-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <%
          Dim j, alid
          j = 0
          Do While Not rsList.EOF
            j = j + 1
            alid = rsList("ID_ALBUM")
          %>
          <tr>
            <td class="col-num"><%= j %></td>
            <td class="col-title"><span class="cell-note"><svg class="icon"><use href="#i-list"/></svg></span><span class="song-name"><%= H(rsList("TITLE_ALBUM") & "") %></span></td>
            <td class="muted"><%= H(rsList("ALBUM_IMAGE_PATH") & "") %></td>
            <td class="col-plays"><% If Not IsNull(rsList("RELEASE_YEAR")) Then %><%= rsList("RELEASE_YEAR") %><% Else %>&mdash;<% End If %></td>
            <td class="col-plays"><%= rsList("TRACK_COUNT") %></td>
            <td class="col-actions">
              <a class="btn-icon" href="<%= VRoot() %>album.asp?id=<%= alid %>" title="View album page"><svg class="icon"><use href="#i-note"/></svg></a>
              <a class="btn-icon" href="<%= VRoot() %>admin/albums.asp?edit=<%= alid %>#tracks" title="Edit album and track list"><svg class="icon"><use href="#i-pencil"/></svg></a>
              <form class="inline-form-del" method="post" action="<%= VRoot() %>admin/albums.asp" onsubmit="return confirm(""Delete this album? Its track list will be removed."")">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<%= alid %>">
                <button type="submit" class="btn-icon btn-icon-danger" title="Delete album"><svg class="icon"><use href="#i-trash"/></svg></button>
              </form>
            </td>
          </tr>
          <%
            rsList.MoveNext
          Loop
          rsList.Close
          %>
        </tbody>
      </table>
    </div>
    <% End If %>
  </section>

</main>

<!--#include file="../includes/footer.asp"-->
<script src="<%= VRoot() %>js/app.js"></script>
</body>
</html>
