<%@ Language="VBScript" %>
<!--#include file="../includes/db.asp"-->
<%
'=====================================================================
' admin/artists.asp - artist management (admin only).
' Create / edit / delete artists.
'=====================================================================
RequireAdmin

Dim action, artistId, artistName, artistLast, artistImage
Dim editId, rsEdit, rsList, rsCount, nList

action = LCase(Request.Form("action") & "")

'--------------------------------------------------------------- create
If action = "create" Then
    artistName = Trim(Request.Form("name") & "")
    artistLast = Trim(Request.Form("lastname") & "")
    artistImage = Trim(Request.Form("image") & "")
    If Len(artistName) = 0 Then
        SetFlash "The artist name is required."
    Else
        Query("INSERT INTO TBL_ARTIST (ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE) VALUES (?, ?, ?)", _
            Left(artistName, 100), Left(artistLast, 100), Left(artistImage, 255))
        SetFlash "Artist created: " & Left(artistName, 100)
    End If
    Redirect VRoot() & "admin/artists.asp"
End If

'--------------------------------------------------------------- update
If action = "update" Then
    artistId = ToInt(Request.Form("id"))
    artistName = Trim(Request.Form("name") & "")
    artistLast = Trim(Request.Form("lastname") & "")
    artistImage = Trim(Request.Form("image") & "")
    If Len(artistName) = 0 Then
        SetFlash "The artist name is required."
        Redirect VRoot() & "admin/artists.asp?edit=" & artistId
    End If
    Query("UPDATE TBL_ARTIST SET ARTIST_NAME = ?, ARTIST_LASTNAME = ?, ARTIST_IMAGE = ? WHERE ID_ARTIST = ?", _
        Left(artistName, 100), Left(artistLast, 100), Left(artistImage, 255), artistId)
    SetFlash "Artist updated: " & Left(artistName, 100)
    Redirect VRoot() & "admin/artists.asp"
End If

'--------------------------------------------------------------- delete
If action = "delete" Then
    artistId = ToInt(Request.Form("id"))
    If artistId > 0 Then
        Query("DELETE FROM TBL_PLAYER WHERE ID_ARTIST = ?", artistId)
        Query("DELETE FROM TBL_ARTIST WHERE ID_ARTIST = ?", artistId)
        SetFlash "Artist deleted."
    End If
    Redirect VRoot() & "admin/artists.asp"
End If

'--- load data for the view -----------------------------------------
Set rsList = Query("SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
    "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = a.ID_ARTIST) AS SONG_COUNT " & _
    "FROM TBL_ARTIST a ORDER BY a.ARTIST_NAME, a.ARTIST_LASTNAME")

Dim rsCount, nList
Set rsCount = Query("SELECT COUNT(*) AS N FROM TBL_ARTIST")
If rsCount Is Nothing Then
    nList = 0
Else
    nList = rsCount("N")
    rsCount.Close
End If

editId = ToInt(Request.QueryString("edit"))
If editId > 0 Then
    Set rsEdit = Query("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = ?", editId)
    If Not rsEdit Is Nothing Then
        If rsEdit.EOF Then
            rsEdit.Close
            Set rsEdit = Nothing
            editId = 0
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
<title>PoliMusic - Manage artists</title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body>

<!--#include file="../includes/layout.asp"-->

<main class="container">

  <%= DBErrorBanner() %>

  <section class="panel-head">
    <div>
      <h1 class="hero-title" style="font-size:26px">Manage artists</h1>
      <p class="panel-sub">Create, edit and delete the artists of the catalog.</p>
    </div>
    <a class="btn btn-ghost btn-sm" href="<%= VRoot() %>default.asp?tab=artists">
      <svg class="icon"><use href="#i-prev"/></svg> Back to artists
    </a>
  </section>

  <% If editId > 0 And Not rsEdit Is Nothing Then %>
  <!-- ==================== edit artist ==================== -->
  <section class="panel form-panel">
    <div class="panel-head">
      <div>
        <h2><svg class="icon"><use href="#i-pencil"/></svg> Edit artist #<%= editId %></h2>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%= VRoot() %>admin/artists.asp">Cancel</a>
    </div>
    <form method="post" action="<%= VRoot() %>admin/artists.asp">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="id" value="<%= editId %>">
      <div class="field-row">
        <div class="field">
          <label for="eName">Artist name</label>
          <input type="text" id="eName" name="name" maxlength="100" value="<%= H(rsEdit("ARTIST_NAME") & "") %>" required>
        </div>
        <div class="field">
          <label for="eLast">Last name</label>
          <input type="text" id="eLast" name="lastname" maxlength="100" value="<%= H(rsEdit("ARTIST_LASTNAME") & "") %>">
        </div>
        <div class="field">
          <label for="eImage">Image path</label>
          <input type="text" id="eImage" name="image" maxlength="255" value="<%= H(rsEdit("ARTIST_IMAGE") & "") %>">
          <div class="hint">Path inside the app, e.g. <code>~/ArtistImages/artist1.jpg</code></div>
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Save changes</button>
    </form>
  </section>
  <% End If %>

  <!-- ==================== create artist ==================== -->
  <details class="panel form-panel" <% If editId = 0 Then %>open<% End If %>>
    <summary class="form-summary"><svg class="icon"><use href="#i-plus"/></svg> Create a new artist</summary>
    <form method="post" action="<%= VRoot() %>admin/artists.asp">
      <input type="hidden" name="action" value="create">
      <div class="field-row">
        <div class="field">
          <label for="cName">Artist name</label>
          <input type="text" id="cName" name="name" maxlength="100" placeholder="e.g. Ana" required>
        </div>
        <div class="field">
          <label for="cLast">Last name</label>
          <input type="text" id="cLast" name="lastname" maxlength="100" placeholder="e.g. Gabriel">
        </div>
        <div class="field">
          <label for="cImage">Image path</label>
          <input type="text" id="cImage" name="image" maxlength="255" placeholder="~/ArtistImages/artist1.jpg">
          <div class="hint">Path inside the app, e.g. <code>~/ArtistImages/artist1.jpg</code></div>
        </div>
      </div>
      <button type="submit" class="btn btn-primary">Create artist</button>
    </form>
  </details>

  <!-- ==================== artist list ==================== -->
  <section class="panel">
    <div class="panel-head">
      <div>
        <h2>All artists</h2>
        <p class="panel-sub"><%= nList %> artist(s) in the catalog.</p>
      </div>
    </div>
    <% If rsList Is Nothing Or rsList.EOF Then %>
    <div class="empty">
      <svg class="icon"><use href="#i-user"/></svg>
      <p>There are no artists yet. Create the first one using the form above.</p>
    </div>
    <% Else %>
    <div class="table-wrap">
      <table class="song-table">
        <thead>
          <tr>
            <th class="col-num">#</th>
            <th>Artist</th>
            <th>Image path</th>
            <th class="col-plays">Songs</th>
            <th class="col-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <%
          Dim i, aid
          i = 0
          Do While Not rsList.EOF
            i = i + 1
            aid = rsList("ID_ARTIST")
          %>
          <tr>
            <td class="col-num"><%= i %></td>
            <td class="col-title"><span class="cell-note"><svg class="icon"><use href="#i-user"/></svg></span><span class="song-name"><%= H(rsList("ARTIST_NAME") & "") %><% If Len(rsList("ARTIST_LASTNAME") & "") > 0 Then %> <%= H(rsList("ARTIST_LASTNAME")) %><% End If %></span></td>
            <td class="muted"><%= H(rsList("ARTIST_IMAGE") & "") %></td>
            <td class="col-plays"><%= rsList("SONG_COUNT") %></td>
            <td class="col-actions">
              <a class="btn-icon" href="<%= VRoot() %>artist.asp?id=<%= aid %>" title="View artist page"><svg class="icon"><use href="#i-note"/></svg></a>
              <a class="btn-icon" href="<%= VRoot() %>admin/artists.asp?edit=<%= aid %>" title="Edit artist"><svg class="icon"><use href="#i-pencil"/></svg></a>
              <form class="inline-form-del" method="post" action="<%= VRoot() %>admin/artists.asp" onsubmit="return confirm(""Delete this artist? The links to their songs will be removed."")">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<%= aid %>">
                <button type="submit" class="btn-icon btn-icon-danger" title="Delete artist"><svg class="icon"><use href="#i-trash"/></svg></button>
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
