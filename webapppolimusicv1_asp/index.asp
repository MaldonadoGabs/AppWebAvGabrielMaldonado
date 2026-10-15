<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<%
'=====================================================================
' index.asp - default document.
' Sends visitors straight to the dashboard when they are already
' signed in, otherwise to the sign-in screen (login.asp).
'=====================================================================
If Len(Session("USER_ID") & "") > 0 Then
    Redirect VRoot() & "default.asp"
Else
    Redirect VRoot() & "login.asp"
End If
%>
