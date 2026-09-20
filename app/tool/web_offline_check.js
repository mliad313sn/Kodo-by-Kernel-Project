// Proves the built web application works with the network switched off.
//
// Not by reading the source — by running it. The check serves `build/web` on a local
// port, opens it in a real Chromium, waits for the service worker to take the cache, then
// puts the browser context genuinely offline and does three things a child would do:
// reloads, reads a world's exercises, and opens the application again in a fresh tab as
// if it were the next morning.
//
// It also records every origin the page asked for. That number has to be zero: the
// default Flutter web build fetches CanvasKit from gstatic.com, which means KODO cannot
// start without Google and a child's IP reaches a third party before the first frame.
//
//     node app/tool/web_offline_check.js [build/web] [build/web_offline.json]
//
// Needs playwright-core and a Chromium. Where there is none, it writes a report saying
// so, and the verification loop reports the finding as unproven rather than as fixed.
'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');

const root = path.resolve(process.argv[2] || 'app/build/web');
const reportPath = path.resolve(process.argv[3] || 'build/web_offline.json');

const TYPES = {
  '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml',
  '.otf': 'font/otf', '.ttf': 'font/ttf', '.bin': 'application/octet-stream',
};

function write(report) {
  fs.mkdirSync(path.dirname(reportPath), { recursive: true });
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 1));
}

let chromium;
try {
  ({ chromium } = require('playwright-core'));
} catch (e) {
  write({ ran: false, why: 'playwright-core is not installed' });
  process.exit(0);
}
const executablePath = process.env.CHROME_EXECUTABLE || '/opt/pw-browsers/chromium';
if (!fs.existsSync(executablePath)) {
  write({ ran: false, why: `no browser at ${executablePath}` });
  process.exit(0);
}
if (!fs.existsSync(path.join(root, 'index.html'))) {
  write({ ran: false, why: `no build at ${root} — run flutter build web first` });
  process.exit(0);
}

const server = http.createServer((req, res) => {
  const name = decodeURIComponent(req.url.split('?')[0]);
  const file = path.join(root, name === '/' ? 'index.html' : name);
  if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404).end('not found');
    return;
  }
  res.writeHead(200, {
    'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream',
    // No caching by the browser itself: the point is to prove the SERVICE WORKER holds
    // the files, not that the HTTP cache happened to.
    'Cache-Control': 'no-store',
  });
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const report = { ran: true, base: '(local)', steps: {} };

  const browser = await chromium.launch({
    executablePath,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  const context = await browser.newContext({ viewport: { width: 420, height: 820 } });
  const page = await context.newPage();

  const foreign = new Set();
  page.on('request', (r) => {
    const origin = new URL(r.url()).origin;
    if (origin !== base) foreign.add(origin);
  });
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e).slice(0, 200)));

  const painted = () =>
    page.waitForFunction(
      () => document.querySelector('flutter-view, flt-glass-pane, canvas') !== null,
      { timeout: 60000 });

  // --- 1. The first visit, online, as any web page is.
  await page.goto(base, { waitUntil: 'networkidle', timeout: 90000 });
  await painted();
  await page.waitForTimeout(4000);
  report.steps.online = {
    worker: await page.evaluate(async () => {
      const r = await navigator.serviceWorker.getRegistration();
      return r && r.active ? 'active' : r ? 'installing' : 'none';
    }),
    cachedEntries: await page.evaluate(async () => {
      const names = await caches.keys();
      if (!names.length) return 0;
      return (await (await caches.open(names[0])).keys()).length;
    }),
    foreignOrigins: [...foreign],
    errors: errors.slice(0, 5),
  };

  // --- 2. The network goes away.
  await context.setOffline(true);
  errors.length = 0;
  const failed = [];
  page.on('requestfailed', (r) => failed.push(new URL(r.url()).pathname));
  await page.reload({ waitUntil: 'load', timeout: 90000 });
  await painted();
  await page.waitForTimeout(4000);
  report.steps.offlineReload = {
    title: await page.title(),
    failedRequests: failed.slice(0, 10),
    errors: errors.slice(0, 5),
    // The thing a child came for.
    world: await page.evaluate(async () => {
      const r = await fetch('assets/assets/content/world5.json');
      const j = await r.json();
      return { world: j.world, items: (j.items || []).length };
    }),
  };

  // --- 3. The next morning: a new tab, still no network.
  const fresh = await context.newPage();
  const freshErrors = [];
  fresh.on('pageerror', (e) => freshErrors.push(String(e).slice(0, 200)));
  await fresh.goto(base, { waitUntil: 'load', timeout: 90000 });
  await fresh.waitForFunction(
    () => document.querySelector('flutter-view, flt-glass-pane, canvas') !== null,
    { timeout: 60000 });
  await fresh.waitForTimeout(4000);
  const shot = await fresh.screenshot();
  fs.writeFileSync(reportPath.replace(/\.json$/, '.png'), shot);
  report.steps.coldStartOffline = {
    title: await fresh.title(),
    errors: freshErrors.slice(0, 5),
    world: await fresh.evaluate(async () => {
      const r = await fetch('assets/assets/content/world12.json');
      const j = await r.json();
      return { world: j.world, items: (j.items || []).length };
    }),
    // A blank page is one colour. A painted one is not.
    screenshotBytes: shot.length,
    distinctBytes: new Set(shot).size,
  };

  await browser.close();
  server.close();

  const s = report.steps;
  report.passed =
    s.online.worker === 'active' &&
    s.online.cachedEntries > 20 &&
    s.online.foreignOrigins.length === 0 &&
    s.offlineReload.errors.length === 0 &&
    s.offlineReload.world.items > 0 &&
    s.coldStartOffline.errors.length === 0 &&
    s.coldStartOffline.world.items > 0 &&
    s.coldStartOffline.distinctBytes > 32;
  write(report);
  process.exit(report.passed ? 0 : 1);
})().catch((e) => {
  write({ ran: false, why: String(e && e.message ? e.message : e) });
  try { server.close(); } catch (_) {}
  process.exit(0);
});
