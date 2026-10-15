/* Screenshot the PoliMusic preview pages with Playwright Chromium.
 * Usage: node _tests/shot_preview.js
 * Captures console/page errors so JS problems surface during the run.
 *
 * Note: fullPage screenshots duplicate position:fixed elements (player bar)
 * during stitching, so each page is captured as viewport shots: the top of
 * the page and (for long pages) the bottom.
 */
const path = require("path");
const { chromium } = require("playwright");

const ROOT = "C:/Users/gabri/source/repos/AppWebAvGabrielMaldonado/webapppolimusicv1_asp";
const PREVIEW = path.join(ROOT, "_preview");
const SHOTS = path.join(PREVIEW, "shots");

const pages = [
  "login",
  "dashboard-user",
  "dashboard-admin",
  "catalog-user",
  "playlists-user",
  "playlist-detail",
  "search",
  "admin-songs",
];

(async () => {
  const browser = await chromium.launch({ args: ["--no-sandbox"] });
  let problems = 0;
  for (const name of pages) {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    const msgs = [];
    page.on("console", (m) => {
      if (m.type() === "error" || m.type() === "warning") msgs.push(m.type() + ": " + m.text());
    });
    page.on("pageerror", (e) => msgs.push("pageerror: " + e.message));
    await page.goto("file:///" + PREVIEW + "/" + name + ".html");
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(700);
    const shot = path.join(SHOTS, name + ".png");
    await page.screenshot({ path: shot });                       // top of page

    // if the page scrolls, also capture the bottom (player stays fixed in view)
    const scrollH = await page.evaluate(() => document.body.scrollHeight);
    if (scrollH > 1100) {
      await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
      await page.waitForTimeout(400);
      await page.screenshot({ path: path.join(SHOTS, name + "-bottom.png") });
    }
    const bad = msgs.filter((m) => !/favicon/i.test(m));
    if (bad.length) { problems += bad.length; console.log(`[${name}] console issues:`); bad.forEach((m) => console.log("   " + m)); }
    else console.log(`[${name}] ok -> ${path.basename(shot)}${scrollH > 1100 ? " (+bottom)" : ""}`);
    await page.close();
  }
  await browser.close();
  console.log(problems ? `\n${problems} console issue(s) found` : "\nAll pages rendered with no console errors");
})().catch((e) => { console.error("FATAL", e); process.exit(1); });
