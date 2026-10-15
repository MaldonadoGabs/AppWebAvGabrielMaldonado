<%@ Language="VBScript" %>
<%
'=====================================================================
' includes/db.asp
' Core data-access layer and shared helpers for PoliMusic.
' Classic ASP / VBScript - SQL Server backend.
'---------------------------------------------------------------------
' * Every SQL statement goes through the parameterized Query() helper
'   (ADODB.Command + parameters) to protect against SQL injection.
' * The connection string is provided by the project; several provider
'   strategies are attempted at runtime so the app works with either
'   MSOLEDBSQL or the legacy SQLOLEDB driver.
'=====================================================================
Option Explicit

'------------------------------ constants -----------------------------
Const CONN_STRING = "Server=apoc;Database=BDD_PoliMusic;User Id=usr_polimusic;Password=Politecnica1;Encrypt=True;TrustServerCertificate=True;"

' ADODB enumerated constants (avoids depending on adovbs.inc)
Const adCmdText     = 1
Const adVarChar     = 200
Const adInteger     = 3
Const adDBTimeStamp = 135
Const adParamInput  = 1
Const adStateOpen   = 1

Const vbTextCompare = 1

'--------------------------- shared state ----------------------------
Dim gConn
Dim gDBError
gDBError = ""

'=====================================================================
' GetConn - returns the shared ADODB connection (opened lazily).
' Tries several provider strategies; returns Nothing if all fail.
'=====================================================================
Function GetConn()
    If Not (gConn Is Nothing) Then
        If gConn.State = adStateOpen Then
            Set GetConn = gConn
            Exit Function
        End If
    End If
    Dim variants(3), i, conn
    variants(0) = "Provider=MSOLEDBSQL;" & CONN_STRING
    variants(1) = CONN_STRING                      ' ADODB default provider
    variants(2) = "Provider=SQLOLEDB;" & CONN_STRING
    variants(3) = "Provider=SQLOLEDB;Server=apoc;Database=BDD_PoliMusic;User Id=usr_polimusic;Password=Politecnica1;"
    Set conn = Server.CreateObject("ADODB.Connection")
    gDBError = ""
    For i = 0 To 3
        On Error Resume Next
        conn.Open variants(i)
        If Err.Number = 0 Then
            On Error GoTo 0
            Set gConn = conn
            Set GetConn = conn
            Exit Function
        End If
        gDBError = Err.Description
        Err.Clear
        On Error GoTo 0
    Next
    Set GetConn = Nothing
End Function

Sub CloseConn()
    On Error Resume Next
    If Not (gConn Is Nothing) Then
        If gConn.State = adStateOpen Then gConn.Close
    End If
    On Error GoTo 0
End Sub

'=====================================================================
' Query - executes a PARAMETERIZED SQL statement.
' Usage:  Set rs = Query("SELECT ... WHERE id = ?", 5)
' Returns the recordset, or Nothing when it fails (see gDBError).
'=====================================================================
Function Query(ByVal sql, ParamArray args())
    Dim cmd, rs, i, v, ptype
    Set Query = Nothing
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = GetConn()
    If cmd.ActiveConnection Is Nothing Then
        If Len(gDBError) = 0 Then gDBError = "Could not open a connection to the database."
        Exit Function
    End If
    cmd.CommandText = sql
    cmd.CommandType = adCmdText
    For i = 0 To UBound(args)
        v = args(i)
        If IsNull(v) Then v = ""
        If IsDate(v) Then
            ptype = adDBTimeStamp
        ElseIf IsNumeric(v) And InStr(CStr(v), ".") = 0 Then
            ptype = adInteger
        Else
            ptype = adVarChar
        End If
        cmd.Parameters.Append cmd.CreateParameter("p" & (i + 1), ptype, adParamInput, 255, v)
    Next
    On Error Resume Next
    Set rs = cmd.Execute
    If Err.Number <> 0 Then
        gDBError = Err.Description
        Err.Clear
    Else
        Set Query = rs
    End If
    On Error GoTo 0
End Function

'=====================================================================
' HTML / URL helpers
'=====================================================================

' H - HTML-escapes any value for safe output (prevents XSS)
Function H(ByVal s)
    If IsNull(s) Or IsEmpty(s) Then
        H = ""
    Else
        H = Server.HTMLEncode(CStr(s))
    End If
End Function

' JSStr - escapes a string so it is safe inside a JS string literal
Function JSStr(ByVal s)
    s = CStr(s)
    s = Replace(s, "\", "\\")
    s = Replace(s, """", "\""")
    s = Replace(s, "'", "\'")
    s = Replace(s, vbCr, "\r")
    s = Replace(s, vbLf, "\n")
    s = Replace(s, "</", "<\/")
    JSStr = s
End Function

' XmlUnEsc - reverses the entity escaping produced by FOR XML PATH
Function XmlUnEsc(ByVal s)
    s = CStr(s)
    s = Replace(s, "&lt;", "<")
    s = Replace(s, "&gt;", ">")
    s = Replace(s, "&quot;", """")
    s = Replace(s, "&apos;", "'")
    s = Replace(s, "&amp;", "&")
    XmlUnEsc = s
End Function

' VRoot - virtual path of the application root ("/" or "/AppName/").
' Detected at runtime from the IIS metabase path; falls back to "/".
' (Change to "/YourVirtualDir/" if your IIS uses a custom metabase.)
Function VRoot()
    Dim md, p
    md = Request.ServerVariables("APPL_MD_PATH") & ""
    p = InStr(1, md, "/ROOT/", vbTextCompare)
    If p > 0 Then
        Dim app
        app = Mid(md, p + 6)
        If Len(app) > 0 Then
            VRoot = "/" & app & "/"
            Exit Function
        End If
    End If
    VRoot = "/"
End Function

' MediaURL - resolves a DB path like "~/songFiles/x.mp3" to a real URL
Function MediaURL(ByVal p)
    Dim s
    s = Trim(p & "")
    If s = "" Then
        MediaURL = ""
        Exit Function
    End If
    If LCase(Left(s, 4)) = "http" Then
        MediaURL = s
        Exit Function
    End If
    If Left(s, 2) = "~/" Then
        MediaURL = VRoot() & Mid(s, 3)
    ElseIf Left(s, 1) = "/" Then
        MediaURL = VRoot() & Mid(s, 2)
    Else
        MediaURL = VRoot() & s
    End If
End Function

' FmtDate - friendly date (e.g. "12 Oct 2026")
Function FmtDate(ByVal d)
    If IsNull(d) Or IsEmpty(d) Then
        FmtDate = ""
        Exit Function
    End If
    If Not IsDate(d) Then
        FmtDate = CStr(d)
        Exit Function
    End If
    FmtDate = Day(d) & " " & MonthName(Month(d), True) & " " & Year(d)
End Function

' ToInt - safe integer conversion (returns 0 for anything non-numeric)
Function ToInt(ByVal v)
    Dim n
    On Error Resume Next
    n = CLng(v)
    If Err.Number = 0 Then
        ToInt = n
    Else
        ToInt = 0
        Err.Clear
    End If
    On Error GoTo 0
End Function

'=====================================================================
' TBL_CATALOG helpers (user types and playlist types live there)
'=====================================================================
Function CatalogText(ByVal parentCode, ByVal code)
    Dim rs
    Set rs = Query("SELECT VALUE FROM TBL_CATALOG WHERE COD_CATALOG_PARENT = ? AND COD_CATALOG = ?", CStr(parentCode), CStr(code))
    If rs Is Nothing Then
        CatalogText = CStr(code)
    ElseIf rs.EOF Then
        CatalogText = CStr(code)
        rs.Close
    Else
        CatalogText = CStr(rs.Fields("VALUE").Value)
        rs.Close
    End If
End Function

Function CatalogOptions(ByVal parentCode, ByVal selectedCode)
    Dim rs, html, code
    html = ""
    Set rs = Query("SELECT COD_CATALOG, VALUE FROM TBL_CATALOG WHERE COD_CATALOG_PARENT = ? ORDER BY COD_CATALOG", CStr(parentCode))
    If Not rs Is Nothing Then
        Do While Not rs.EOF
            code = CStr(rs.Fields("COD_CATALOG").Value)
            html = html & "<option value=""" & H(code) & """"
            If code = CStr(selectedCode) Then html = html & " selected"
            html = html & ">" & H(rs.Fields("VALUE").Value) & "</option>"
            rs.MoveNext
        Loop
        rs.Close
    End If
    CatalogOptions = html
End Function

'=====================================================================
' Authentication helpers
'=====================================================================
Function CurrentUserID()
    If Len(Session("USER_ID") & "") > 0 Then
        CurrentUserID = CLng(Session("USER_ID"))
    Else
        CurrentUserID = 0
    End If
End Function

Function IsAdmin()
    IsAdmin = False
    If Len(Session("USER_ID") & "") > 0 Then
        If CLng(Session("USER_TYPE")) = 1 Then IsAdmin = True
    End If
End Function

Sub RequireLogin()
    If Len(Session("USER_ID") & "") = 0 Then
        Redirect VRoot() & "login.asp"
    End If
End Sub

Sub RequireAdmin()
    If Len(Session("USER_ID") & "") = 0 Then
        Redirect VRoot() & "login.asp"
    ElseIf Not IsAdmin() Then
        Redirect VRoot() & "default.asp"
    End If
End Sub

Sub Redirect(ByVal url)
    CloseConn
    Response.Redirect url
    Response.End
End Sub

' DBErrorBanner - renders a friendly alert when a query failed
Function DBErrorBanner()
    If Len(gDBError) > 0 Then
        DBErrorBanner = "<div class='alert alert-error'><strong>Database unavailable.</strong> " & H(gDBError) & "</div>"
    Else
        DBErrorBanner = ""
    End If
End Function

'=====================================================================
' SHA-1 (pure VBScript)
' The seeded user 'username1' stores a SHA-1 hash of the password, so
' login compares either the plain text or the SHA-1 hex digest.
'=====================================================================
Function Add32(ByVal x, ByVal y)
    Dim xl, xh, yl, yh, l, h
    xl = x And &HFFFF
    xh = (x - xl) / &H10000
    yl = y And &HFFFF
    yh = (y - yl) / &H10000
    l = xl + yl
    h = xh + yh + (l \ &H10000)
    l = l And &HFFFF
    h = ((h + &H8000) And &HFFFF) - &H8000
    Add32 = h * &H10000 + l
End Function

Function ROL32(ByVal x, ByVal n)
    n = n And 31
    Dim lo, hiU, t, nlo, nhi, hv
    lo = x And &HFFFF
    hiU = ((x - lo) / &H10000) And &HFFFF
    If n >= 16 Then
        t = lo
        lo = hiU
        hiU = t
        n = n - 16
    End If
    If n > 0 Then
        nlo = ((lo * 2 ^ n) Or (hiU \ 2 ^ (16 - n))) And &HFFFF
        nhi = ((hiU * 2 ^ n) Or (lo \ 2 ^ (16 - n))) And &HFFFF
        lo = nlo
        hiU = nhi
    End If
    hv = hiU - IIf(hiU >= &H8000, &H10000, 0)
    ROL32 = hv * &H10000 + lo
End Function

Function Word32(ByVal b0, ByVal b1, ByVal b2, ByVal b3)
    Dim hi, lo, hv
    hi = (b0 * &H100) + b1
    lo = (b2 * &H100) + b3
    hv = hi - IIf(hi >= &H8000, &H10000, 0)
    Word32 = hv * &H10000 + lo
End Function

Function Hex32(ByVal x)
    Dim r, i, b(3)
    r = x
    For i = 3 To 0 Step -1
        b(i) = r And &HFF
        r = (r - b(i)) / &H100
    Next
    Hex32 = Right("0" & Hex(b(0)), 2) & Right("0" & Hex(b(1)), 2) & Right("0" & Hex(b(2)), 2) & Right("0" & Hex(b(3)), 2)
End Function

Function SHA1Hex(ByVal s)
    ' Convert the string to its UTF-8 byte representation
    Dim bytes(), n, i, cp
    ReDim bytes(0)
    n = 0
    For i = 1 To Len(s)
        cp = AscW(Mid(s, i, 1))
        If cp < &H80 Then
            ReDim Preserve bytes(n)
            bytes(n) = cp
            n = n + 1
        ElseIf cp < &H800 Then
            ReDim Preserve bytes(n + 1)
            bytes(n) = &HC0 Or (cp \ &H40)
            bytes(n + 1) = &H80 Or (cp And &H3F)
            n = n + 2
        Else
            ReDim Preserve bytes(n + 2)
            bytes(n) = &HE0 Or (cp \ &H1000)
            bytes(n + 1) = &H80 Or ((cp \ &H40) And &H3F)
            bytes(n + 2) = &H80 Or (cp And &H3F)
            n = n + 3
        End If
    Next

    ' Padding: 0x80, zeros until 56 mod 64, then 64-bit big-endian length
    Dim bitLen
    bitLen = n * 8
    ReDim Preserve bytes(n)
    bytes(n) = &H80
    n = n + 1
    Do While (n Mod 64) <> 56
        ReDim Preserve bytes(n)
        bytes(n) = 0
        n = n + 1
    Loop
    For i = 7 To 0 Step -1
        ReDim Preserve bytes(n)
        bytes(n) = (bitLen \ (2 ^ (8 * i))) And &HFF
        n = n + 1
    Next

    ' Process 512-bit blocks
    Dim h0, h1, h2, h3, h4, a, b, c, d, e, f, k, temp
    h0 = &H67452301
    h1 = &HEFCDAB89
    h2 = &H98BADCFE
    h3 = &H10325476
    h4 = &HC3D2E1F0
    Dim w(79), j, base
    For base = 0 To n - 1 Step 64
        For j = 0 To 15
            w(j) = Word32(bytes(base + j * 4), bytes(base + j * 4 + 1), bytes(base + j * 4 + 2), bytes(base + j * 4 + 3))
        Next
        For j = 16 To 79
            w(j) = ROL32(w(j - 3) Xor w(j - 8) Xor w(j - 14) Xor w(j - 16), 1)
        Next
        a = h0
        b = h1
        c = h2
        d = h3
        e = h4
        For j = 0 To 79
            If j < 20 Then
                f = (b And c) Or ((Not b) And d)
                k = &H5A827999
            ElseIf j < 40 Then
                f = b Xor c Xor d
                k = &H6ED9EBA1
            ElseIf j < 60 Then
                f = (b And c) Or (b And d) Or (c And d)
                k = &H8F1BBCDC
            Else
                f = b Xor c Xor d
                k = &HCA62C1D6
            End If
            temp = Add32(Add32(Add32(ROL32(a, 5), f), Add32(e, k)), w(j))
            e = d
            d = c
            c = ROL32(b, 30)
            b = a
            a = temp
        Next
        h0 = Add32(h0, a)
        h1 = Add32(h1, b)
        h2 = Add32(h2, c)
        h3 = Add32(h3, d)
        h4 = Add32(h4, e)
    Next
    SHA1Hex = LCase(Hex32(h0) & Hex32(h1) & Hex32(h2) & Hex32(h3) & Hex32(h4))
End Function

' CheckPassword - accepts either a plain-text password or its SHA-1 hash
Function CheckPassword(ByVal stored, ByVal input)
    CheckPassword = False
    If StrComp(CStr(stored), CStr(input), vbTextCompare) = 0 Then
        CheckPassword = True
        Exit Function
    End If
    If Len(CStr(stored)) = 40 Then
        ' stored value looks like a SHA-1 hex digest
        On Error Resume Next
        Dim digest
        digest = SHA1Hex(CStr(input))
        If Err.Number = 0 Then
            If LCase(CStr(stored)) = digest Then CheckPassword = True
        End If
        Err.Clear
        On Error GoTo 0
    End If
End Function
%>
