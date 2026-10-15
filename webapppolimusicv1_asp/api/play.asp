<%@ Language="VBScript" %>
<!--#include file="../includes/db.asp"-->
<%
'=====================================================================
' api/play.asp - tiny JSON endpoint that increments the play counter
' of a song. Called (fire and forget) by the JS player.
'=====================================================================
Response.ContentType = "application/json"

Dim id
id = ToInt(Request.QueryString("id"))

If id > 0 Then
    Query("UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS, 0) + 1 WHERE ID_SONG = ?", id)
    If Len(gDBError) = 0 Then
        Response.Write "{""ok"":true}"
    Else
        Response.Write "{""ok"":false,""error"":""database error""}"
    End If
Else
    Response.Write "{""ok"":false,""error"":""invalid song id""}"
End If

CloseConn
%>
