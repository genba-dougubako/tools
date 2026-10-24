const { chromium } = require("playwright");
(async () => {
  const browser = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium-1194/chrome-linux/chrome" }).catch(() => chromium.launch());
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  for (const [file, w, h, out] of [["thumbnail.html", 1920, 1080, "thumbnail.png"], ["icon.html", 512, 512, "icon.png"]]) {
    await page.setViewportSize({ width: w, height: h });
    await page.goto("file://" + process.cwd() + "/" + file);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(300);
    const loaded = await page.evaluate(() => [...document.fonts].filter(f => f.status === "loaded").map(f => f.family));
    console.log(file, "fonts loaded:", [...new Set(loaded)].join(", "));
    await page.screenshot({ path: out, clip: { x: 0, y: 0, width: w, height: h } });
  }
  await browser.close();
})();
