<%@ Language="VBScript" %>
<%
'=====================================================================
' includes/songs.asp
' Shared "song list" component used by every page that lists songs.
'---------------------------------------------------------------------
' Usage:
'   Set rs = Query(SONG_COLS & " FROM TBL_SONG s WHERE ... ")
'   LoadSongs rs
'   ... <%= SongsJson() %>        (feeds the JS player)
'   ... <%= SongTable(True, True, "play,add,adminedit,admindelete") %>
'=====================================================================

' Columns shared by every song query. Pages append their own
' " FROM ... WHERE ... ORDER BY ..." suffix.
Const SONG_COLS = _
    "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS, 0) AS PLAYS, " & _
    "STUFF((SELECT ', ' + a.ARTIST_NAME + ISNULL(' ' + NULLIF(a.ARTIST_LASTNAME, ''), '') " & _
    "       FROM TBL_PLAYER p JOIN TBL_ARTIST a ON p.ID_ARTIST = a.ID_ARTIST " & _
    "       WHERE p.ID_SONG = s.ID_SONG ORDER BY a.ARTIST_NAME " & _
    "       FOR XML PATH('')), 1, 2, '') AS ARTISTS, " & _
    "STUFF((SELECT ', ' + al.TITLE_ALBUM " & _
    "       FROM TBL_TRACKLIST t JOIN TBL_ALBUM al ON t.ID_ALBUM = al.ID_ALBUM " & _
    "       WHERE t.ID_SONG = s.ID_SONG ORDER BY al.TITLE_ALBUM " & _
    "       FOR XML PATH('')), 1, 2, '') AS ALBUMS, " & _
    "(SELECT TOP 1 al.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t " & _
    "  JOIN TBL_ALBUM al ON t.ID_ALBUM = al.ID_ALBUM " & _
    "  WHERE t.ID_SONG = s.ID_SONG) AS COVER "

' gSongs: array of [id, name, path, plays, artists, albums, cover]
Dim gSongs
Dim gSongCount

Sub LoadSongs(rs)
    Dim i
    gSongCount = 0
    ReDim gSongs(0)
    If rs Is Nothing Then Exit Sub
    Do While Not rs.EOF
        ReDim Preserve gSongs(gSongCount)
        gSongs(gSongCount) = Array( _
            CLng(rs("ID_SONG")), _
            CStr(rs("SONG_NAME")), _
            CStr(rs("SONG_PATH")), _
            CLng(rs("PLAYS")), _
            SafeCol(rs, "ARTISTS"), _
            SafeCol(rs, "ALBUMS"), _
            SafeCol(rs, "COVER"))
        gSongCount = gSongCount + 1
        rs.MoveNext
    Loop
    rs.Close
End Sub

' SafeCol - reads a column that may not exist in every query
Function SafeCol(rs, ByVal fieldName)
    On Error Resume Next
    SafeCol = XmlUnEsc(rs.Fields(fieldName).Value & "")
    If Err.Number <> 0 Then
        SafeCol = ""
        Err.Clear
    End If
    On Error GoTo 0
End Function

' SongsJson - the current list as a JS array for the player
Function SongsJson()
    Dim i, s, json
    json = "["
    For i = 0 To gSongCount - 1
        If i > 0 Then json = json & ","
        s = gSongs(i)
        json = json & "{""i"":" & s(0) & _
            ",""t"":""" & JSStr(s(1)) & """" & _
            ",""a"":""" & JSStr(s(4)) & """" & _
            ",""al"":""" & JSStr(s(5)) & """" & _
            ",""img"":""" & JSStr(MediaURL(s(6))) & """" & _
            ",""s"":""" & JSStr(MediaURL(s(2))) & """}"
    Next
    SongsJson = json & "]"
End Function

' SongTable - renders the styled HTML song list table.
'   showArtist / showAlbum : show the extra columns
'   opts : comma flags -> "play", "add" (add to playlist),
'          "adminedit", "admindelete", "remove:<playlistId>"
Function SongTable(ByVal showArtist, ByVal showAlbum, ByVal opts)
    Dim html, i, s, colspan, removePid
    html = "<div class='table-wrap'><table class='song-table'><thead><tr>" & _
        "<th class='col-num' title='Track number'>#</th>" & _
        "<th class='col-title'>Title</th>"
    If showArtist Then html = html & "<th class='col-artist'>Artist(s)</th>"
    If showAlbum Then html = html & "<th class='col-album'>Album(s)</th>"
    html = html & "<th class='col-plays' title='Times played'>Plays</th>" & _
        "<th class='col-actions'>Actions</th></tr></thead><tbody>"

    If gSongCount = 0 Then
        colspan = 5
        If showArtist Then colspan = colspan + 1
        If showAlbum Then colspan = colspan + 1
        html = html & "<tr class='row-empty'><td colspan='" & colspan & "'>No songs to show.</td></tr>"
    End If

    removePid = 0
    If InStr(opts, "remove:") > 0 Then
        removePid = CLng(Mid(opts, InStr(opts, "remove:") + 7))
    End If

    For i = 0 To gSongCount - 1
        s = gSongs(i)
        html = html & "<tr data-idx='" & i & "'>" & _
            "<td class='col-num'>" & (i + 1) & "</td>" & _
            "<td class='col-title'><span class='cell-note'><svg class='icon'><use href='#i-note'/></svg></span><span class='song-name'>" & H(s(1)) & "</span></td>"
        If showArtist Then
            html = html & "<td class='col-artist'>" & If(Len(s(4)) > 0, H(s(4)), "<span class='muted'>&mdash;</span>") & "</td>"
        End If
        If showAlbum Then
            html = html & "<td class='col-album'>" & If(Len(s(5)) > 0, H(s(5)), "<span class='muted'>&mdash;</span>") & "</td>"
        End If
        html = html & "<td class='col-plays'>" & s(3) & "</td>" & _
            "<td class='col-actions'>" & _
            "<button type='button' class='btn-play' data-idx='" & i & "' title='Play " & H(s(1)) & "' aria-label='Play " & H(s(1)) & "'><svg class='icon'><use href='#i-play'/></svg></button>"

        If InStr(opts, "add") > 0 Then
            html = html & "<button type='button' class='btn-icon btn-add-pl' data-song='" & s(0) & "' data-name='" & H(s(1)) & "' title='Add " & H(s(1)) & " to a playlist' aria-label='Add to playlist'><svg class='icon'><use href='#i-plus'/></svg></button>"
        End If
        If InStr(opts, "adminedit") > 0 Then
            html = html & "<a class='btn-icon' href='" & VRoot() & "admin/songs.asp?edit=" & s(0) & "' title='Edit song' aria-label='Edit song'><svg class='icon'><use href='#i-pencil'/></svg></a>"
        End If
        If InStr(opts, "admindelete") > 0 Then
            html = html & "<form class='inline-form-del' method='post' action='" & VRoot() & "admin/songs.asp' onsubmit='return confirm(""Delete the song " & H(s(1)) & ""? This cannot be undone."")'>" & _
                "<input type='hidden' name='action' value='delete'><input type='hidden' name='id' value='" & s(0) & "'>" & _
                "<button type='submit' class='btn-icon btn-icon-danger' title='Delete song' aria-label='Delete song'><svg class='icon'><use href='#i-trash'/></svg></button></form>"
        End If
        If removePid > 0 Then
            html = html & "<form class='inline-form-del' method='post' action='" & VRoot() & "playlist.asp' onsubmit='return confirm(""Remove " & H(s(1)) & "" from this playlist?"")'>" & _
                "<input type='hidden' name='action' value='remove'><input type='hidden' name='playlist' value='" & removePid & "'><input type='hidden' name='song' value='" & s(0) & "'>" & _
                "<button type='submit' class='btn-icon btn-icon-danger' title='Remove from playlist' aria-label='Remove from playlist'><svg class='icon'><use href='#i-trash'/></svg></button></form>"
        End If
        html = html & "</td></tr>"
    Next

    html = html & "</tbody></table></div>"
    SongTable = html
End Function
%>
