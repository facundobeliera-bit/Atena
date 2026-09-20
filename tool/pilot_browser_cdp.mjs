import fs from 'node:fs';

const targets = await (await fetch('http://127.0.0.1:9223/json')).json();
const page = targets.find((target) => target.type === 'page' && target.url.includes('127.0.0.1:8777'));
if (!page) throw new Error('Pilot browser page not found');
const socket = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener('open', resolve, { once: true });
  socket.addEventListener('error', reject, { once: true });
});
let nextId = 1;
const pending = new Map();
socket.addEventListener('message', (event) => {
  const response = JSON.parse(event.data);
  if (!response.id || !pending.has(response.id)) return;
  const { resolve, reject } = pending.get(response.id);
  pending.delete(response.id);
  if (response.error) reject(new Error(response.error.message));
  else resolve(response.result);
});
function call(method, params = {}) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
}
await call('Page.enable');
await call('Runtime.enable');
await call('Accessibility.enable');
const action = process.argv[2] ?? 'snapshot';
async function click(x, y) {
  await call('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await call('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
}
if (action === 'click') {
  const x = Number(process.argv[3]);
  const y = Number(process.argv[4]);
  await click(x, y);
} else if (action === 'login') {
  if (!process.env.PILOT_BROWSER_EMAIL || !process.env.PILOT_BROWSER_PASSWORD) {
    throw new Error('Pilot browser credentials unavailable');
  }
  await click(480, 139);
  await call('Input.insertText', { text: process.env.PILOT_BROWSER_EMAIL });
  await click(480, 188);
  await call('Input.insertText', { text: process.env.PILOT_BROWSER_PASSWORD });
  await click(610, 240);
  await new Promise((resolve) => setTimeout(resolve, 3000));
} else if (action === 'type') {
  for (const char of process.env.PILOT_BROWSER_TEXT ?? '') {
    await call('Input.insertText', { text: char });
  }
} else if (action === 'key') {
  const key = process.argv[3];
  await call('Input.dispatchKeyEvent', { type: 'keyDown', key, code: key });
  await call('Input.dispatchKeyEvent', { type: 'keyUp', key, code: key });
} else if (action === 'wheel') {
  await call('Input.dispatchMouseEvent', {
    type: 'mouseWheel', x: 800, y: 620,
    deltaX: 0, deltaY: Number(process.argv[3] ?? 600),
  });
} else if (action === 'reload') {
  await call('Page.reload', { ignoreCache: true });
  await new Promise((resolve) => setTimeout(resolve, 5000));
}
await new Promise((resolve) => setTimeout(resolve, 1500));
const ax = await call('Accessibility.getFullAXTree');
const labels = ax.nodes.map((node) => node.name?.value).filter(Boolean);
const screenshot = await call('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
fs.mkdirSync('build/pilot-browser', { recursive: true });
fs.writeFileSync('build/pilot-browser/latest.png', Buffer.from(screenshot.data, 'base64'));
console.log(JSON.stringify({ action, labels: labels.slice(0, 70) }));
socket.close();
