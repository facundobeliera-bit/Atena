import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import vm from 'node:vm';

// HTML parsing normalizes CRLF before the browser computes inline CSP hashes.
const html = readFileSync(new URL('../web/auth/return.html', import.meta.url), 'utf8').replace(/\r\n/g, '\n');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
function render(search = '', hash = '', historyFails = false) {
  const nodes = {status: {textContent: 'Continuá en Atena'}, detail: {textContent: 'Comprobar el estado ingresando en Atena'}};
  const callbacks = [];
  const changes = [];
  const location = {search, hash, pathname: '/auth/return.html'};
  vm.runInNewContext(script, {
    URLSearchParams,
    window: {location, history: {replaceState(state, title, url) {
      if (historyFails) throw Error('Unavailable');
      changes.push(url); location.search = ''; location.hash = '';
    }}},
    document: {getElementById: id => nodes[id], addEventListener: (event, fn) => { assert.equal(event, 'DOMContentLoaded'); callbacks.push(fn); }},
    // Any attempt to persist, fetch or log secrets fails the test.
    fetch() { throw Error('Network forbidden'); },
    console: {log() { throw Error('Logging forbidden'); }, error() { throw Error('Logging forbidden'); }},
  });
  assert.equal(callbacks.length, 1);
  callbacks[0]();
  return {nodes, changes, location};
}
test('callback script is pinned by CSP; no external resources or SDK', () => {
  const hash = createHash('sha256').update(script).digest('base64');
  assert.ok(html.includes(`script-src 'sha256-${hash}'`));
  assert.ok(html.includes("connect-src 'none'"));
  assert.ok(html.includes('name="referrer" content="no-referrer"'));
  assert.doesNotMatch(html, /(?:src=|https?:\/\/|localStorage|sessionStorage|innerHTML|document\.cookie)/);
  assert.ok(html.includes('href="/" rel="noreferrer"'));
});
test('PKCE code and implicit tokens are discarded without creating a session', () => {
  for (const [search, hash] of [['?code=TEST_CODE', ''], ['', '#access_token=TEST_ACCESS&refresh_token=TEST_REFRESH']]) {
    const result = render(search, hash);
    assert.deepEqual(result.changes, ['/auth/return.html']);
    assert.equal(result.location.search + result.location.hash, '');
    assert.doesNotMatch(JSON.stringify(result.nodes), /TEST_CODE|TEST_ACCESS|TEST_REFRESH/);
    assert.equal(result.nodes.status.textContent, 'Continuá en Atena');
  }
});
test('expired or used links show a neutral error; untrusted descriptions never render', () => {
  for (const params of [['?error_code=otp_expired&error_description=UNTRUSTED', ''], ['', '#error=access_denied&error_description=UNTRUSTED']]) {
    const result = render(...params);
    assert.equal(result.nodes.status.textContent, 'El enlace no pudo completarse');
    assert.doesNotMatch(JSON.stringify(result.nodes), /UNTRUSTED/);
    assert.deepEqual(result.changes, ['/auth/return.html']);
  }
});
test('no confirmation or attacker redirect is inferred from URL parameters', () => {
  for (const query of ['', '?confirmed=true', '?redirect_to=https://untrusted.invalid/&next=//untrusted.invalid']) {
    const result = render(query);
    assert.equal(result.nodes.status.textContent, 'Continuá en Atena');
    assert.deepEqual(result.changes, ['/auth/return.html']);
  }
});
test('unavailable history instructs closing the tab without exposing parameters', () => {
  const result = render('?code=TEST_CODE', '', true);
  assert.match(result.nodes.detail.textContent, /Cerrá esta pestaña/);
  assert.doesNotMatch(JSON.stringify(result.nodes), /TEST_CODE/);
});

test('recovery return discards credentials and never claims a password reset', () => {
  for (const [query, fragment] of [
    ['', '#type=recovery&access_token=TEST_RECOVERY&refresh_token=TEST_REFRESH'],
    ['?type=recovery&code=TEST_RECOVERY', ''],
  ]) {
    const result = render(query, fragment);
    assert.deepEqual(result.changes, ['/auth/return.html']);
    assert.equal(result.location.hash + result.location.search, '');
    assert.equal(result.nodes.status.textContent, 'Recuperación no disponible en este retorno');
    assert.match(result.nodes.detail.textContent, /no cambia contraseñas ni inicia una sesión/);
    assert.doesNotMatch(JSON.stringify(result.nodes), /TEST_RECOVERY|TEST_REFRESH|contraseña actualizada/i);
  }
});

test('recovery does not hide errors or the instruction to close an uncleared URL', () => {
  const failed = render('?type=recovery&error_code=otp_expired', '#access_token=TEST_ACCESS');
  assert.equal(failed.nodes.status.textContent, 'El enlace no pudo completarse');
  const uncleared = render('', '#type=recovery&access_token=TEST_ACCESS', true);
  assert.match(uncleared.nodes.detail.textContent, /Cerrá esta pestaña/);
  assert.doesNotMatch(JSON.stringify(uncleared.nodes), /TEST_ACCESS/);
});
