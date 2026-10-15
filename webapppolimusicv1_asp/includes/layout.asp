<%@ Language="VBScript" %>
<%
'=====================================================================
' includes/layout.asp
' Shared page shell: SVG icons, top bar (welcome + logout + search),
' sticky player, add-to-playlist modal and toast container.
' Include right after <body>.  Pair with includes/footer.asp.
'=====================================================================
Dim pmPlaylistRs, pmHasPlaylists, pmFlash
pmHasPlaylists = False
pmFlash = Session("PM_FLASH") & ""
If Len(pmFlash) > 0 Then Session("PM_FLASH") = ""
Set pmPlaylistRs = Query("SELECT pl.ID_PLAYLIST, pl.TITLE, " & _
    "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = pl.ID_PLAYLIST) AS SONG_COUNT " & _
    "FROM TBL_PLAYLIST pl WHERE pl.ID_USER = ? ORDER BY pl.TITLE", CurrentUserID())
If Not pmPlaylistRs Is Nothing Then
    If Not pmPlaylistRs.EOF Then pmHasPlaylists = True
End If
%>
<svg xmlns="http://www.w3.org/2000/svg" style="display:none" aria-hidden="true">
  <symbol id="i-play" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></symbol>
  <symbol id="i-pause" viewBox="0 0 24 24"><path d="M6 5h4v14H6zm8 0h4v14h-4z"/></symbol>
  <symbol id="i-prev" viewBox="0 0 24 24"><path d="M6 6h2v12H6zm3.5 6L18 18V6z"/></symbol>
  <symbol id="i-next" viewBox="0 0 24 24"><path d="M16 6h2v12h-2zM6 6l8.5 6L6 18z"/></symbol>
  <symbol id="i-note" viewBox="0 0 24 24"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6z"/></symbol>
  <symbol id="i-search" viewBox="0 0 24 24"><path d="M15.5 14h-.79l-.28-.27a6.5 6.5 0 1 0-.7.7l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0A4.5 4.5 0 1 1 14 9.5 4.5 4.5 0 0 1 9.5 14z"/></symbol>
  <symbol id="i-logout" viewBox="0 0 24 24"><path d="M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5-5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z"/></symbol>
  <symbol id="i-plus" viewBox="0 0 24 24"><path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/></symbol>
  <symbol id="i-trash" viewBox="0 0 24 24"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></symbol>
  <symbol id="i-pencil" viewBox="0 0 24 24"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 0 0 0-1.41l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></symbol>
  <symbol id="i-close" viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></symbol>
  <symbol id="i-volume" viewBox="0 0 24 24"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0 0 14 7.97v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></symbol>
  <symbol id="i-list" viewBox="0 0 24 24"><path d="M3 13h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm4 4h14v-2H7v2zm0 4h14v-2H7v2zM7 7v2h14V7H7z"/></symbol>
  <symbol id="i-user" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></symbol>
</svg>

<header class="topbar">
  <a class="brand" href="<%= VRoot() %>default.asp">
    <span class="brand-icon"><svg class="icon"><use href="#i-note"/></svg></span>
    <span class="brand-name">Poli<em>Music</em></span>
  </a>

  <nav class="mainnav" aria-label="Main navigation">
    <a class="navlink" href="<%= VRoot() %>default.asp">Home</a>
    <a class="navlink" href="<%= VRoot() %>default.asp?tab=artists">Artists</a>
    <a class="navlink" href="<%= VRoot() %>default.asp?tab=albums">Albums</a>
    <a class="navlink" href="<%= VRoot() %>default.asp?tab=playlists">Playlists</a>
    <% If IsAdmin() Then %>
    <div class="dropdown">
      <button type="button" class="navlink dropdown-toggle" aria-haspopup="true" aria-expanded="false">Manage <span class="caret"></span></button>
      <div class="dropdown-menu" role="menu">
        <a role="menuitem" href="<%= VRoot() %>admin/songs.asp"><svg class="icon"><use href="#i-note"/></svg> Songs</a>
        <a role="menuitem" href="<%= VRoot() %>admin/artists.asp"><svg class="icon"><use href="#i-user"/></svg> Artists</a>
        <a role="menuitem" href="<%= VRoot() %>admin/albums.asp"><svg class="icon"><use href="#i-list"/></svg> Albums</a>
      </div>
    </div>
    <% End If %>
  </nav>

  <form class="searchbox" action="<%= VRoot() %>search.asp" method="get" role="search">
    <svg class="icon searchbox-icon"><use href="#i-search"/></svg>
    <input type="search" name="q" value="<%= H(Request.QueryString("q")) %>" placeholder="Search songs, artists, albums..." aria-label="Search songs, artists and albums">
  </form>

  <div class="userbox">
    <span class="userbox-hello">Welcome, <strong><%= H(Session("USER_NAME")) %></strong></span>
    <span class="badge <% If IsAdmin() Then %>badge-admin<% Else %>badge-user<% End If %>"><% If IsAdmin() Then %>Administrator<% Else %>User<% End If %></span>
    <a class="btn btn-outline btn-logout" href="<%= VRoot() %>logout.asp"><svg class="icon"><use href="#i-logout"/></svg> Log out</a>
  </div>
</header>

<% If Len(pmFlash) > 0 Then %>
<div class="flash-wrap"><div class="alert alert-success"><%= H(pmFlash) %></div></div>
<% End If %>

<!-- ============================ player ============================ -->
<div class="player" id="player">
  <div class="p-now">
    <span class="thumb thumb-player" id="pThumb">
      <img id="pThumbImg" alt="" hidden>
      <span class="thumb-note"><svg class="icon"><use href="#i-note"/></svg></span>
    </span>
    <span class="p-meta">
      <span class="p-title" id="pTitle">Nothing playing</span>
      <span class="p-sub" id="pSub">Pick a song from the list to start listening</span>
    </span>
  </div>

  <div class="p-controls">
    <div class="p-buttons">
      <button type="button" class="p-btn" id="pPrev" title="Previous song" aria-label="Previous song"><svg class="icon"><use href="#i-prev"/></svg></button>
      <button type="button" class="p-btn p-btn-main" id="pToggle" title="Play / Pause" aria-label="Play or pause">
        <svg class="icon p-icon-play" id="pIconPlay"><use href="#i-play"/></svg>
        <svg class="icon p-icon-pause" id="pIconPause" hidden><use href="#i-pause"/></svg>
      </button>
      <button type="button" class="p-btn" id="pNext" title="Next song" aria-label="Next song"><svg class="icon"><use href="#i-next"/></svg></button>
    </div>
    <div class="p-seek">
      <span class="p-time" id="pCur">0:00</span>
      <input type="range" id="pSeek" min="0" max="1000" value="0" step="1" aria-label="Seek">
      <span class="p-time" id="pDur">0:00</span>
    </div>
  </div>

  <div class="p-volume">
    <svg class="icon"><use href="#i-volume"/></svg>
    <input type="range" id="pVol" min="0" max="100" value="80" aria-label="Volume">
  </div>

  <audio id="audio" preload="metadata"></audio>
</div>

<!-- ===================== add-to-playlist modal ===================== -->
<div class="modal-backdrop" id="addModal" hidden>
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="addModalTitle">
    <div class="modal-head">
      <h3 id="addModalTitle">Add to playlist</h3>
      <button type="button" class="modal-close" id="addModalClose" title="Close" aria-label="Close"><svg class="icon"><use href="#i-close"/></svg></button>
    </div>
    <p class="modal-song" id="addModalSong"></p>
    <div class="modal-body" id="addModalBody">
      <% If pmHasPlaylists Then %>
        <% Do While Not pmPlaylistRs.EOF %>
        <form class="modal-item" method="post" action="<%= VRoot() %>playlist.asp">
          <input type="hidden" name="action" value="add">
          <input type="hidden" name="playlist" value="<%= pmPlaylistRs("ID_PLAYLIST") %>">
          <input type="hidden" class="pl-song-input" name="song" value="">
          <button type="submit" class="modal-item-btn">
            <svg class="icon"><use href="#i-list"/></svg>
            <span class="modal-item-title"><%= H(pmPlaylistRs("TITLE")) %></span>
            <span class="modal-item-sub"><%= pmPlaylistRs("SONG_COUNT") %> song(s)</span>
          </button>
        </form>
        <% pmPlaylistRs.MoveNext : Loop %>
      <% Else %>
        <p class="empty-inline">You do not have any playlists yet. Create one from the <strong>Playlists</strong> tab and it will show up here.</p>
      <% End If %>
    </div>
  </div>
</div>

<div class="toasts" id="toasts" aria-live="polite"></div>
<script>window.PM_VROOT = "<%= VRoot() %>";</script>
