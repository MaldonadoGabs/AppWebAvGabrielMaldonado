<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<%
'=====================================================================
' logout.asp - ends the session and returns to the login screen.
'=====================================================================
Session.Abandon()
Response.Redirect VRoot() & "login.asp?logout=1"
%>
