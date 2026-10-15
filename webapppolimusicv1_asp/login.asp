<%@ Language="VBScript" %>
<!--#include file="includes/db.asp"-->
<%
'=====================================================================
' login.asp - authentication screen.
' Validates the credentials against TBL_USER and stores the logged-in
' user in session variables:
'     Session("USER_ID")    - numeric user id
'     Session("USER_NAME")  - username (shown in the welcome message)
'     Session("USER_TYPE")  - 0 = normal user, 1 = admin
' Passwords may be stored either in plain text or as a SHA-1 hash.
'=====================================================================
Dim errMsg, uname, pwd
errMsg = ""

If Len(Session("USER_ID") & "") > 0 Then
    Redirect VRoot() & "default.asp"
End If

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    uname = Trim(Request.Form("username") & "")
    pwd = Request.Form("password") & ""

    If uname = "" Or pwd = "" Then
        errMsg = "Please enter both your username and your password."
    Else
        Dim rs
        Set rs = Query("SELECT ID_USER, USERNAME, PASSWORD, USER_TYPE FROM TBL_USER WHERE USERNAME = ?", uname)
        If rs Is Nothing Then
            errMsg = "The database is currently unavailable. Please try again later."
        ElseIf rs.EOF Then
            rs.Close
            errMsg = "Invalid username or password."
        ElseIf CheckPassword(rs("PASSWORD"), pwd) Then
            Session("USER_ID") = CLng(rs("ID_USER"))
            Session("USER_NAME") = CStr(rs("USERNAME"))
            Session("USER_TYPE") = CLng(rs("USER_TYPE"))
            rs.Close
            CloseConn
            Response.Redirect VRoot() & "default.asp"
            Response.End
        Else
            rs.Close
            errMsg = "Invalid username or password."
        End If
    End If
End If

Dim isLogout
isLogout = (Request.QueryString("logout") = "1")
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic - Sign in</title>
<link rel="icon" href="<%= VRoot() %>images/favicon.ico">
<link rel="stylesheet" href="<%= VRoot() %>css/styles.css">
</head>
<body class="auth-page">

<svg xmlns="http://www.w3.org/2000/svg" style="display:none" aria-hidden="true">
  <symbol id="i-note" viewBox="0 0 24 24"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></symbol>
</svg>

<main class="auth-wrap">
  <div class="auth-card">
    <a class="brand auth-brand" href="<%= VRoot() %>default.asp">
      <span class="brand-icon"><svg class="icon"><use href="#i-note"/></svg></span>
      <span class="brand-name">Poli<em>Music</em></span>
    </a>
    <h1 class="auth-title">Welcome back</h1>
    <p class="auth-sub">Sign in to browse the catalog and play your music.</p>

    <% If isLogout Then %>
    <div class="alert alert-info">You have been logged out. See you soon!</div>
    <% End If %>

    <% If errMsg <> "" Then %>
    <div class="alert alert-error"><%= H(errMsg) %></div>
    <% End If %>

    <form method="post" action="<%= VRoot() %>login.asp" autocomplete="on">
      <div class="field">
        <label for="username">Username</label>
        <input type="text" id="username" name="username" value="<%= H(uname) %>" required autofocus placeholder="your username">
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" required placeholder="your password">
      </div>
      <button type="submit" class="btn btn-primary btn-block">Sign in</button>
    </form>

    <div class="auth-hint">
      <strong>Demo accounts</strong>
      <span><code>userNormal</code> / <code>12345678</code> &mdash; normal user</span>
      <span><code>userAdmin</code> / <code>12345678</code> &mdash; administrator</span>
      <span><code>username1</code> / <code>12345678</code> &mdash; normal user</span>
    </div>
  </div>
</main>

</body>
</html>
