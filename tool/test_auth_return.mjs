import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import vm from 'node:vm';

// Contract tests of the actual return script. Mock HTTP is NOT a real Auth test.
const html = readFileSync(new URL('../web/auth/return.html', import.meta.url), 'utf8').replace(/\r\n/g, '\n');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const proof = 'a'.repeat(64), link = '#type=recovery&token_hash=' + proof;
const grant = {access_token: 'offline-fixture-not-valid-jwt', refresh_token: 'FICTIONAL_REFRESH', expires_in: 3600, user: {id: 'recovery-user'}};
const context = {auth_user_id: 'recovery-user', session_guard_version: 1};
const revoked = {code: '42501', message: 'Session revoked or expired'};
const ok = (body, status = 200) => ({status, body});
function render({search = '', hash = '', historyFails = false, key = 'sb_publishable_fictionaltestonly', replies = []} = {}) {
  const nodes = Object.fromEntries(['status', 'detail', 'verify', 'reset', 'password', 'repeat', 'save'].map(id => [id, {
    textContent: '', value: '', hidden: id === 'verify' || id === 'reset', disabled: false,
    events: {}, addEventListener(event, fn) {this.events[event] = fn;},
  }]));
  nodes.status.textContent = 'Continuá en Atena';
  const callbacks = [], changes = [], requests = [], events = {};
  const location = {search, hash, pathname: '/auth/return.html'};
  let now = 1000;
  vm.runInNewContext(script, {
    URLSearchParams, AbortController, setTimeout, clearTimeout,
    Date: {now: () => now},
    window: {location, addEventListener: (e, fn) => events[e] = fn,
      history: {replaceState(state, title, url) {
        if (historyFails) throw Error('Unavailable');
        changes.push(url); location.search = ''; location.hash = '';
      }}},
    document: {getElementById: id => nodes[id], querySelector: () => ({content: key}),
      addEventListener: (event, fn) => {assert.equal(event, 'DOMContentLoaded'); callbacks.push(fn);}},
    async fetch(url, options) {
      assert.equal(location.search + location.hash, '', 'URL must be clean before network');
      requests.push({url, options});
      assert.equal(options.credentials, 'omit');
      assert.equal(options.redirect, 'error');
      assert.equal(options.cache, 'no-store');
      assert.equal(options.referrerPolicy, 'no-referrer');
      let result = replies.shift();
      if (typeof result === 'function') result = await result();
      if (result instanceof Error) throw result;
      assert.ok(result, 'Unexpected network request');
      return {ok: result.status >= 200 && result.status < 300, status: result.status,
        json: async () => structuredClone(result.body)};
    },
    console: {log() {throw Error('Logging forbidden');}, error() {throw Error('Logging forbidden');}},
  });
  callbacks[0]();
  return {nodes, changes, location, requests, events, advance: ms => now += ms,
    verify: () => nodes.verify.events.click(),
    async save(password = 'FICTIONAL-test-password', repeat = password) {
      nodes.password.value = password; nodes.repeat.value = repeat;
      await nodes.reset.events.submit({preventDefault() {}});
    }};
}

test('CSP pins script and only pilot network; no SDK/storage/tracking/HTML injection', () => {
  const hash = createHash('sha256').update(script).digest('base64');
  assert.ok(html.includes(`script-src 'sha256-${hash}'`));
  assert.ok(html.includes('connect-src https://eaegvxxxkvhdukbkydvy.supabase.co;'));
  assert.ok(html.includes('name="referrer" content="no-referrer"'));
  assert.doesNotMatch(html, /(?:src=|localStorage|sessionStorage|innerHTML|document\.cookie)/);
  assert.ok(html.includes('href="/" rel="noreferrer"'));
  const headers = readFileSync(new URL('../web/_headers', import.meta.url), 'utf8');
  assert.match(headers, /^\/auth\/return\*/);
  assert.match(headers, /Cache-Control: no-store/);
  assert.match(headers, /frame-ancestors 'none'/);
});
test('proposed mail template uses recovery proof in fragment, not signup/session URL', () => {
  const template = readFileSync(new URL('../supabase/templates/recovery.html', import.meta.url), 'utf8');
  assert.match(template, /return\.html#type=recovery&amp;token_hash=\{\{ \.TokenHash \}\}/);
  assert.doesNotMatch(template, /ConfirmationURL|access_token|refresh_token|\?token_hash/);
});
test('normal confirmation is informational; arbitrary redirects are ignored', () => {
  for (const search of ['', '?confirmed=true', '?redirect_to=https://untrusted.invalid']) {
    const r = render({search});
    assert.equal(r.nodes.status.textContent, 'Continuá en Atena');
    assert.equal(r.nodes.reset.hidden, true);
    assert.deepEqual(r.changes, ['/auth/return.html']);
    assert.equal(r.requests.length, 0);
  }
});
test('implicit signup/recovery tokens and PKCE codes cannot authorize a reset', async () => {
  for (const hash of ['#type=signup&token_hash=' + proof,
    '#type=recovery&access_token=TEST_ACCESS&refresh_token=TEST_REFRESH',
    '#type=recovery&code=TEST_CODE', '#type=recovery&type=recovery&token_hash=' + proof]) {
    const r = render({hash});
    await r.verify(); await r.save();
    assert.equal(r.nodes.reset.hidden, true);
    assert.equal(r.requests.length, 0);
    assert.equal(r.location.hash, '');
    assert.doesNotMatch(JSON.stringify(r.nodes), /TEST_ACCESS|TEST_REFRESH|TEST_CODE/);
  }
});
test('query proof, missing config, errors and failed history all fail closed', async () => {
  for (const settings of [
    {search: '?type=recovery&token_hash=' + proof},
    {hash: link, key: '__ATENA_PUBLISHABLE_KEY__'},
    {hash: link, historyFails: true},
    {hash: link, search: '?error_code=otp_expired&error_description=UNTRUSTED'},
  ]) {
    const r = render(settings);
    await r.verify(); await r.save();
    assert.equal(r.requests.length, 0);
    assert.equal(r.nodes.reset.hidden, true);
    assert.doesNotMatch(JSON.stringify(r.nodes), /UNTRUSTED/);
  }
});
test('valid recovery verifies server proof and guard before password; global logout after update', async () => {
  const r = render({hash: link, replies: [ok(grant), ok(context), ok(context), ok({id: 'recovery-user'}), ok(revoked, 403), ok(null, 204)]});
  assert.equal(r.requests.length, 0, 'Email prefetch cannot consume the link');
  await r.save(); assert.equal(r.requests.length, 0);
  await r.verify();
  assert.equal(r.nodes.reset.hidden, false);
  assert.deepEqual(JSON.parse(r.requests[0].options.body), {token_hash: proof, type: 'recovery'});
  assert.equal(r.requests[0].options.headers.Authorization, undefined);
  await r.save();
  assert.equal(r.nodes.status.textContent, 'Contraseña actualizada');
  assert.equal(r.nodes.reset.hidden, true);
  assert.equal(r.nodes.password.value + r.nodes.repeat.value, '');
  assert.deepEqual(r.requests.map(x => [new URL(x.url).pathname + new URL(x.url).search, x.options.method]), [
    ['/auth/v1/verify', 'POST'], ['/rest/v1/rpc/atena_authenticated_context', 'POST'],
    ['/rest/v1/rpc/atena_authenticated_context', 'POST'],
    ['/auth/v1/user', 'PUT'], ['/rest/v1/rpc/atena_authenticated_context', 'POST'], ['/auth/v1/logout?scope=global', 'POST'],
  ]);
  assert.deepEqual(JSON.parse(r.requests[3].options.body), {password: 'FICTIONAL-test-password'});
  assert.doesNotMatch(JSON.stringify(r.requests), /FICTIONAL_REFRESH/);
  await r.save(); assert.equal(r.requests.length, 6, 'Completed session cannot be reused');
});
test('expired, reused and signup proof relabeled recovery are rejected by Auth', async () => {
  for (const reason of ['expired', 'reused', 'signup-token']) {
    const r = render({hash: link, replies: [ok({message: reason}, 403)]});
    await r.verify(); await r.save();
    assert.equal(r.nodes.status.textContent, 'El enlace no pudo completarse');
    assert.equal(r.nodes.reset.hidden, true);
    assert.equal(r.requests.length, 1);
    assert.equal(JSON.parse(r.requests[0].options.body).type, 'recovery');
    assert.doesNotMatch(JSON.stringify(r.nodes), new RegExp(reason));
  }
});
test('missing guard, foreign identity, revoked/disabled context deny update', async () => {
  for (const reply of [ok({auth_user_id: 'recovery-user'}), ok({...context, auth_user_id: 'foreign'}), ok(revoked, 403)]) {
    const r = render({hash: link, replies: [ok(grant), reply]});
    await r.verify(); await r.save();
    assert.equal(r.nodes.reset.hidden, true);
    assert.equal(r.requests.length, 2);
  }
});
test('password length and repetition checked without network; session expires in memory', async () => {
  const r = render({hash: link, replies: [ok(grant), ok(context)]});
  await r.verify();
  for (const [a, b] of [['short', 'short'], ['long-enough-password', 'different'], ['a'.repeat(129), 'a'.repeat(129)]]) await r.save(a, b);
  assert.equal(r.requests.length, 2);
  r.advance(600001); await r.save();
  assert.equal(r.nodes.reset.hidden, true);
  assert.equal(r.requests.length, 2);
});
test('network loss during update never claims success or retries silently', async () => {
  const r = render({hash: link, replies: [ok(grant), ok(context), ok(context), Error('UNTRUSTED secret response')]});
  await r.verify(); await r.save(); await r.save();
  assert.equal(r.nodes.status.textContent, 'No se pudo confirmar el cambio');
  assert.equal(r.requests.length, 4);
  assert.doesNotMatch(r.nodes.detail.textContent, /UNTRUSTED/);
});
test('wrong update identity cannot be treated as successful', async () => {
  const r = render({hash: link, replies: [ok(grant), ok(context), ok(context), ok({id: 'foreign'})]});
  await r.verify(); await r.save();
  assert.equal(r.nodes.status.textContent, 'No se pudo confirmar el cambio');
});
test('global logout failure or missing server cutoff remains explicitly unverified', async () => {
  for (const [cutoff, logout] of [[ok(context), ok(null, 204)], [ok(revoked, 403), ok({}, 500)]]) {
    const r = render({hash: link, replies: [ok(grant), ok(context), ok(context), ok({id: 'recovery-user'}), cutoff, logout]});
    await r.verify(); await r.save();
    assert.equal(r.nodes.status.textContent, 'Contraseña actualizada; comprobación de cierre pendiente');
    assert.equal(r.nodes.reset.hidden, true);
  }
});
test('pagehide aborts pending work and a late response cannot open recovery', async () => {
  let resolve;
  const r = render({hash: link, replies: [() => new Promise(r => resolve = r)]});
  const work = r.verify();
  r.events.pagehide(); resolve(ok(grant)); await work;
  assert.equal(r.requests[0].options.signal.aborted, true);
  assert.equal(r.nodes.reset.hidden, true);
  await r.save(); assert.equal(r.requests.length, 1);
});
test('double clicks do not reuse the OTP', async () => {
  const r = render({hash: link, replies: [ok(grant), ok(context)]});
  await Promise.all([r.verify(), r.verify()]);
  assert.equal(r.requests.length, 2);
});
test('session revoked while the form was open cannot submit a password', async () => {
  const r = render({hash: link, replies: [ok(grant), ok(context), ok(revoked, 403)]});
  await r.verify(); await r.save();
  assert.equal(r.requests.length, 3);
  assert.ok(r.requests.every(r => r.options.method === 'POST'));
  assert.equal(r.nodes.reset.hidden, true);
});
