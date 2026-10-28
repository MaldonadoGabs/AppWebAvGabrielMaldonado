<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PoliMusic - Songs</title>
    <style type="text/css">
        :root {
            --orange: #FB5607;
            --purple: #8338EC;
            --dark: #212529;
            --light: #E9ECEF;
            --muted: #6B7280;
            --line: rgba(33, 37, 53, 0.12);
            --danger: #C1121F;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            padding-bottom: 150px;
            font-family: "Segoe UI", system-ui, -apple-system, Roboto, Arial, sans-serif;
            font-size: 15px;
            line-height: 1.55;
            color: var(--dark);
            background: var(--light);
        }

        a { color: var(--purple); text-decoration: none; }
        a:hover { color: #6D28D9; }

        /* ------------------------------------------------------- top bar */
        .topbar {
            position: sticky;
            top: 0;
            z-index: 50;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 18px;
            flex-wrap: wrap;
            padding: 12px 24px;
            background: #FFFFFF;
            border-bottom: 1px solid var(--line);
            box-shadow: 0 1px 2px rgba(33, 37, 53, 0.05);
        }

        .brand { display: flex; align-items: center; gap: 10px; font-size: 20px; font-weight: 700; }

        .brand-icon {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 34px;
            height: 34px;
            border-radius: 10px;
            color: #FFFFFF;
            font-size: 17px;
            background: linear-gradient(100deg, var(--orange), var(--purple));
        }

        .brand-name em { font-style: normal; color: var(--orange); }

        .userbox { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
        .userbox-hello { color: var(--muted); }
        .userbox-hello strong { color: var(--dark); }

        .badge {
            padding: 2px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
            color: var(--purple);
            background: rgba(131, 56, 236, 0.10);
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 8px 16px;
            border: 1px solid var(--line);
            border-radius: 999px;
            font-size: 14px;
            font-weight: 600;
            color: var(--dark);
            background: #FFFFFF;
            cursor: pointer;
        }

        .btn:hover { border-color: var(--purple); color: var(--purple); }
        .btn-primary { color: #FFFFFF; border-color: transparent; background: linear-gradient(100deg, var(--orange), var(--purple)); }
        .btn-primary:hover { color: #FFFFFF; opacity: 0.92; }

        /* ------------------------------------------------------- layout */
        .container { max-width: 1080px; margin: 0 auto; padding: 24px 20px 0; }

        .card {
            margin-bottom: 22px;
            background: #FFFFFF;
            border: 1px solid var(--line);
            border-radius: 16px;
            box-shadow: 0 1px 2px rgba(33, 37, 53, 0.05), 0 2px 8px rgba(33, 37, 53, 0.06);
            overflow: hidden;
        }

        .card-head {
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            padding: 16px 20px;
            border-bottom: 1px solid var(--line);
        }

        .card-head h2 { margin: 0; font-size: 17px; }
        .muted { color: var(--muted); font-size: 13px; }

        /* -------------------------------------------------- song table */
        .song-table { width: 100%; border-collapse: collapse; }

        .song-table th {
            padding: 10px 20px;
            text-align: left;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: var(--muted);
            background: #F8F9FA;
            border-bottom: 1px solid var(--line);
        }

        .song-table td { padding: 12px 20px; border-bottom: 1px solid var(--line); vertical-align: middle; }
        .song-table tr:last-child td { border-bottom: 0; }
        .song-table tbody tr:hover { background: #FAFAFB; }
        .song-row.is-playing { background: rgba(251, 86, 7, 0.07); }

        .col-num { width: 56px; color: var(--muted); }
        .col-plays { width: 90px; color: var(--muted); }
        .col-actions { width: 190px; text-align: right; }

        .note {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 26px;
            height: 26px;
            margin-right: 10px;
            border-radius: 8px;
            font-size: 13px;
            color: var(--purple);
            background: rgba(131, 56, 236, 0.10);
        }

        .song-row.is-playing .note { color: #FFFFFF; background: var(--orange); }
        .song-name { font-weight: 600; }

        .btn-play {
            padding: 6px 14px;
            border: 1px solid rgba(251, 86, 7, 0.35);
            border-radius: 999px;
            font-size: 13px;
            font-weight: 600;
            color: var(--orange);
            background: rgba(251, 86, 7, 0.08);
            cursor: pointer;
        }

        .btn-play:hover { color: #FFFFFF; background: var(--orange); border-color: var(--orange); }

        .inline { display: inline; }

        .btn-del { margin-left: 8px; font-size: 13px; font-weight: 600; color: var(--danger); }
        .btn-del:hover { color: #8D0D17; }

        .empty { padding: 28px 20px; text-align: center; color: var(--muted); }

        /* -------------------------------------------------- admin form */
        .admin-form { display: flex; align-items: flex-end; gap: 16px; flex-wrap: wrap; padding: 18px 20px; }
        .admin-form label { font-size: 13px; font-weight: 600; color: var(--muted); }
        .admin-form input[type="text"] {
            display: block;
            width: 260px;
            margin-top: 4px;
            padding: 8px 12px;
            font-size: 14px;
            color: var(--dark);
            border: 1px solid var(--line);
            border-radius: 9px;
        }

        .msg { display: block; padding: 12px 20px; font-weight: 600; color: var(--danger); }
        .msg:empty { display: none; }

        /* ----------------------------------------------------- player */
        .player {
            position: fixed;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: 60;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            flex-wrap: wrap;
            padding: 12px 24px;
            background: #FFFFFF;
            border-top: 1px solid var(--line);
            box-shadow: 0 -2px 12px rgba(33, 37, 53, 0.08);
        }

        .p-now { display: flex; align-items: center; gap: 12px; min-width: 0; }

        .p-thumb {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 44px;
            height: 44px;
            border-radius: 12px;
            font-size: 18px;
            color: #FFFFFF;
            background: linear-gradient(100deg, var(--orange), var(--purple));
        }

        .p-meta { display: flex; flex-direction: column; min-width: 0; }
        .p-title { font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 320px; }
        .p-sub { font-size: 12px; color: var(--muted); }

        #audioPlayer { width: 420px; max-width: 100%; }

        @media (max-width: 720px) {
            .col-plays, .col-num { display: none; }
            .p-title { max-width: 180px; }
            #audioPlayer { width: 100%; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <header class="topbar">
            <div class="brand">
                <span class="brand-icon">&#9835;</span>
                <span class="brand-name">Poli<em>Music</em></span>
            </div>
            <div class="userbox">
                <span class="userbox-hello">Welcome, <strong><asp:Label ID="lblUserName" runat="server"></asp:Label></strong></span>
                <span class="badge"><asp:Label ID="lblUserType" runat="server"></asp:Label></span>
                <asp:LinkButton ID="btnLogout" runat="server" CssClass="btn" OnClick="BtnLogout_Click">Log out</asp:LinkButton>
            </div>
        </header>

        <div class="container">

            <asp:Label ID="lblMessage" runat="server" CssClass="msg"></asp:Label>

            <div class="card">
                <div class="card-head">
                    <h2>Songs</h2>
                    <span class="muted">Pick a song to start listening</span>
                </div>

                <table class="song-table">
                    <thead>
                        <tr>
                            <th class="col-num">#</th>
                            <th>Title</th>
                            <th class="col-plays">Plays</th>
                            <th class="col-actions">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Repeater ID="rptSongs" runat="server">
                            <ItemTemplate>
                                <tr class="song-row" data-id="<%# Eval("ID_SONG") %>">
                                    <td class="col-num"><%# Container.ItemIndex + 1 %></td>
                                    <td>
                                        <span class="note">&#9835;</span>
                                        <span class="song-name"><%# HtmlText(Eval("SONG_NAME")) %></span>
                                    </td>
                                    <td class="col-plays"><span data-plays="<%# Eval("ID_SONG") %>"><%# Eval("PLAYS") %></span></td>
                                    <td class="col-actions">
                                        <button type="button" class="btn-play"
                                            data-id="<%# Eval("ID_SONG") %>"
                                            data-src="<%# SongUrl(Eval("SONG_PATH")) %>"
                                            data-name="<%# HtmlAttr(Eval("SONG_NAME")) %>">&#9654; Play</button>
                                        <asp:Panel ID="pnlDelete" runat="server" CssClass="inline" Visible='<%# IsAdmin %>'>
                                            <asp:LinkButton ID="lnkDelete" runat="server" CssClass="btn-del"
                                                CommandName="DeleteSong"
                                                CommandArgument='<%# Eval("ID_SONG") %>'
                                                OnCommand="RptSongs_Command"
                                                OnClientClick="return confirm('Delete this song? This cannot be undone.');">Delete</asp:LinkButton>
                                        </asp:Panel>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>

                <asp:Panel ID="pnlEmpty" runat="server" CssClass="empty" Visible="false">
                    No songs available yet.
                </asp:Panel>
            </div>

            <asp:Panel ID="pnlAdmin" runat="server" CssClass="card" Visible="false">
                <div class="card-head">
                    <h2>Add a song</h2>
                    <span class="muted">Administrator only &middot; MP3, up to 50 MB</span>
                </div>
                <div class="admin-form">
                    <label>
                        Song name
                        <asp:TextBox ID="txtSongName" runat="server" MaxLength="50"></asp:TextBox>
                    </label>
                    <label>
                        MP3 file
                        <asp:FileUpload ID="fupSong" runat="server" />
                    </label>
                    <asp:Button ID="btnAddSong" runat="server" Text="Upload song" CssClass="btn btn-primary" OnClick="BtnAddSong_Click" />
                </div>
            </asp:Panel>

        </div>

        <div class="player">
            <div class="p-now">
                <span class="p-thumb">&#9835;</span>
                <span class="p-meta">
                    <span class="p-title" id="nowTitle">Nothing playing</span>
                    <span class="p-sub" id="nowSub">Pick a song from the list to start listening</span>
                </span>
            </div>
            <audio id="audioPlayer" controls="controls" preload="none"></audio>
        </div>

    </form>

    <script type="text/javascript">
        (function () {
            var audio = document.getElementById('audioPlayer');
            var nowTitle = document.getElementById('nowTitle');
            var nowSub = document.getElementById('nowSub');
            var rows = document.querySelectorAll('.song-row');

            function clearHighlight() {
                for (var i = 0; i < rows.length; i++) {
                    rows[i].className = 'song-row';
                }
            }

            function playSong(button) {
                var src = button.getAttribute('data-src');
                var name = button.getAttribute('data-name');
                var id = button.getAttribute('data-id');
                if (!src) {
                    nowSub.textContent = 'This song has no file associated.';
                    return;
                }

                clearHighlight();
                var row = button.parentNode.parentNode;
                row.className = 'song-row is-playing';
                nowTitle.textContent = name;
                nowSub.textContent = 'Now playing';

                audio.src = src;
                var playing = audio.play();
                if (playing && typeof playing.catch === 'function') {
                    playing.catch(function () { });
                }

                // Increase the PLAYS counter without a postback, so the audio is not interrupted.
                new Image().src = 'PlayCounter.ashx?id=' + encodeURIComponent(id) + '&t=' + new Date().getTime();
                var cell = document.querySelector('[data-plays="' + id + '"]');
                if (cell) {
                    var plays = parseInt(cell.innerHTML, 10);
                    if (!isNaN(plays)) { cell.innerHTML = plays + 1; }
                }
            }

            audio.addEventListener('error', function () {
                if (audio.getAttribute('src')) {
                    nowSub.textContent = 'The audio file could not be loaded.';
                }
            });

            document.addEventListener('click', function (e) {
                var target = e.target;
                while (target && target !== document.body) {
                    if (target.className && target.className.indexOf('btn-play') !== -1) {
                        playSong(target);
                        return;
                    }
                    target = target.parentNode;
                }
            });
        })();
    </script>
</body>
</html>
