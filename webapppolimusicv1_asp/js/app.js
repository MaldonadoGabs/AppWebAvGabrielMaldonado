/* =====================================================================
   PoliMusic - app.js
   HTML5 audio player + UI interactions (add-to-playlist modal, toasts,
   now-playing highlight, image fallbacks).
   ===================================================================== */
(function () {
  "use strict";

  var PM = {};
  window.PM = PM;

  var VROOT = window.PM_VROOT || "/";
  var songs = Array.isArray(window.PM_SONGS) ? window.PM_SONGS : [];
  var current = -1;
  var seeking = false;
  var counted = {};

  var audio = document.getElementById("audio");
  var elTitle = document.getElementById("pTitle");
  var elSub = document.getElementById("pSub");
  var elThumb = document.getElementById("pThumb");
  var elThumbImg = document.getElementById("pThumbImg");
  var btnToggle = document.getElementById("pToggle");
  var iconPlay = document.getElementById("pIconPlay");
  var iconPause = document.getElementById("pIconPause");
  var elSeek = document.getElementById("pSeek");
  var elCur = document.getElementById("pCur");
  var elDur = document.getElementById("pDur");
  var elVol = document.getElementById("pVol");

  /* ---------------------------------------------------------- helpers */
  function fmtTime(t) {
    if (!isFinite(t) || t < 0) return "0:00";
    var m = Math.floor(t / 60);
    var s = Math.floor(t % 60);
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  function el(id) { return document.getElementById(id); }

  PM.toast = function (msg, type) {
    var box = el("toasts");
    if (!box) return;
    var t = document.createElement("div");
    t.className = "toast" + (type ? " toast-" + type : "");
    t.textContent = msg;
    t.addEventListener("click", function () { t.remove(); });
    box.appendChild(t);
    setTimeout(function () { if (t.parentNode) t.remove(); }, 4200);
  };

  function setPlayingIcon(isPlaying) {
    if (!iconPlay || !iconPause) return;
    iconPlay.hidden = isPlaying;
    iconPause.hidden = !isPlaying;
  }

  function highlightRow() {
    var rows = document.querySelectorAll("tr[data-idx]");
    for (var i = 0; i < rows.length; i++) {
      rows[i].classList.toggle("is-playing", Number(rows[i].getAttribute("data-idx")) === current);
    }
  }

  function pingPlayCounter(song) {
    if (!song || counted[song.i]) return;
    counted[song.i] = true;
    try {
      fetch(VROOT + "api/play.asp?id=" + encodeURIComponent(song.i), { method: "GET" }).catch(function () {});
    } catch (e) { /* silent */ }
  }

  /* ---------------------------------------------------------- player */
  function showSong(song) {
    elTitle.textContent = song.t || "Unknown title";
    var sub = song.a || "";
    if (song.al) sub = sub ? sub + " - " + song.al : song.al;
    elSub.textContent = sub || "Unknown artist";
    if (song.img) {
      elThumbImg.src = song.img;
      elThumbImg.hidden = false;
      elThumbImg.classList.remove("img-broken");
    } else {
      elThumbImg.hidden = true;
      elThumbImg.removeAttribute("src");
    }
    elCur.textContent = "0:00";
    elDur.textContent = "0:00";
    elSeek.value = 0;
    highlightRow();
  }

  PM.playIndex = function (i) {
    if (i < 0 || i >= songs.length) return;
    current = i;
    var song = songs[i];
    showSong(song);
    audio.src = song.s;
    var p = audio.play();
    if (p && typeof p.catch === "function") {
      p.catch(function () {
        setPlayingIcon(false);
        PM.toast("Could not play \"" + song.t + "\". The audio file may be missing on the server.", "error");
      });
    }
    pingPlayCounter(song);
    try {
      sessionStorage.setItem("pm_last", JSON.stringify({ i: i, t: song.t, a: song.a, al: song.al, img: song.img }));
    } catch (e) { /* private mode */ }
  };

  PM.toggle = function () {
    if (current < 0) {
      if (songs.length > 0) PM.playIndex(0);
      return;
    }
    if (audio.paused) {
      var p = audio.play();
      if (p && typeof p.catch === "function") {
        p.catch(function () { PM.toast("Playback was blocked by the browser.", "error"); });
      }
    } else {
      audio.pause();
    }
  };

  PM.next = function () {
    if (songs.length === 0) return;
    PM.playIndex(current < 0 ? 0 : (current + 1) % songs.length);
  };

  PM.prev = function () {
    if (songs.length === 0) return;
    PM.playIndex(current <= 0 ? songs.length - 1 : current - 1);
  };

  /* ---------------------------------------------------------- modal */
  PM.openAddModal = function (songId, songName) {
    var modal = el("addModal");
    if (!modal) return;
    el("addModalSong").textContent = "Add \"" + songName + "\" to one of your playlists:";
    var inputs = modal.querySelectorAll(".pl-song-input");
    for (var i = 0; i < inputs.length; i++) inputs[i].value = songId;
    modal.hidden = false;
    var first = modal.querySelector(".modal-item-btn");
    if (first) first.focus();
  };

  PM.closeAddModal = function () {
    var modal = el("addModal");
    if (modal) modal.hidden = true;
  };

  /* ---------------------------------------------------------- wiring */
  function init() {
    if (btnToggle) btnToggle.addEventListener("click", PM.toggle);
    var prev = el("pPrev");
    var next = el("pNext");
    if (prev) prev.addEventListener("click", PM.prev);
    if (next) next.addEventListener("click", PM.next);

    if (audio) {
      audio.addEventListener("play", function () { setPlayingIcon(true); });
      audio.addEventListener("pause", function () { setPlayingIcon(false); });
      audio.addEventListener("ended", function () { PM.next(); });
      audio.addEventListener("timeupdate", function () {
        if (!seeking && audio.duration) {
          elSeek.value = Math.round((audio.currentTime / audio.duration) * 1000);
          elCur.textContent = fmtTime(audio.currentTime);
        }
      });
      audio.addEventListener("durationchange", function () {
        elDur.textContent = fmtTime(audio.duration);
      });
      audio.addEventListener("error", function () {
        if (!audio.src) return;
        var name = current >= 0 && songs[current] ? songs[current].t : "This song";
        setPlayingIcon(false);
        PM.toast("Could not load \"" + name + "\". The audio file may be missing on the server.", "error");
      });

      var vol = 80;
      try { vol = parseInt(localStorage.getItem("pm_vol"), 10); } catch (e) { /* ignore */ }
      if (isNaN(vol)) vol = 80;
      audio.volume = Math.min(100, Math.max(0, vol)) / 100;
      if (elVol) elVol.value = vol;
    }

    if (elSeek) {
      elSeek.addEventListener("pointerdown", function () { seeking = true; });
      elSeek.addEventListener("input", function () {
        if (audio.duration) {
          elCur.textContent = fmtTime((elSeek.value / 1000) * audio.duration);
        }
      });
      var release = function () {
        if (seeking && audio.duration) {
          audio.currentTime = (elSeek.value / 1000) * audio.duration;
        }
        seeking = false;
      };
      elSeek.addEventListener("change", release);
      elSeek.addEventListener("pointerup", release);
    }

    if (elVol) {
      elVol.addEventListener("input", function () {
        audio.volume = elVol.value / 100;
        try { localStorage.setItem("pm_vol", elVol.value); } catch (e) { /* ignore */ }
      });
    }

    /* row play buttons + add-to-playlist buttons (event delegation) */
    document.addEventListener("click", function (ev) {
      var playBtn = ev.target.closest ? ev.target.closest(".btn-play") : null;
      if (playBtn) {
        PM.playIndex(Number(playBtn.getAttribute("data-idx")));
        return;
      }
      var addBtn = ev.target.closest ? ev.target.closest(".btn-add-pl") : null;
      if (addBtn) {
        PM.openAddModal(addBtn.getAttribute("data-song"), addBtn.getAttribute("data-name"));
      }
    });

    /* modal close: button, backdrop, Escape */
    var closeBtn = el("addModalClose");
    if (closeBtn) closeBtn.addEventListener("click", PM.closeAddModal);
    var modal = el("addModal");
    if (modal) {
      modal.addEventListener("click", function (ev) {
        if (ev.target === modal) PM.closeAddModal();
      });
    }
    document.addEventListener("keydown", function (ev) {
      if (ev.key === "Escape") PM.closeAddModal();
    });

    /* broken images fall back to the gradient placeholder */
    document.addEventListener("error", function (ev) {
      if (ev.target && ev.target.tagName === "IMG") {
        ev.target.classList.add("img-broken");
      }
    }, true);

    /* restore the last played song (metadata only, no autoplay) */
    try {
      var last = JSON.parse(sessionStorage.getItem("pm_last") || "null");
      if (last && typeof last.t === "string") {
        current = -1;
        elTitle.textContent = last.t;
        var sub = last.a || "";
        if (last.al) sub = sub ? sub + " - " + last.al : last.al;
        elSub.textContent = sub || "Unknown artist";
        if (last.img) {
          elThumbImg.src = last.img;
          elThumbImg.hidden = false;
        }
      }
    } catch (e) { /* ignore */ }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
