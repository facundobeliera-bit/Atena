import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,writeFileSync,readFileSync,existsSync,rmSync,symlinkSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {randomBytes} from 'node:crypto';
import {pack,restore} from './recovery_bundle.mjs';
test('encrypted isolated bundle preserves database, Storage, configuration and Auth plan',()=>{
 const root=mkdtempSync(path.join(tmpdir(),'atena-recovery-'));try{
 const input=path.join(root,'input');mkdirSync(input);mkdirSync(path.join(input,'storage'));
 const files={'database.dump':'FICTIONAL DATABASE','storage/object.bin':'PRIVATE TEST DOCUMENT','storage/index.json':'[{"name":"object.bin"}]','auth-plan.json':'{"sessions":"must-not-restore"}','configuration.json':'{"environment":"isolated"}'};
 for(const [name,value]of Object.entries(files))writeFileSync(path.join(input,name),value);
 const pass=randomBytes(32).toString('base64url'),encrypted=path.join(root,'bundle.aes');
 assert.equal(pack(input,encrypted,pass).files,5);
 const bytes=readFileSync(encrypted);for(const value of Object.values(files))assert.equal(bytes.includes(Buffer.from(value)),false);
 const target=path.join(root,'restored');assert.equal(restore(encrypted,target,pass).files,5);
 for(const [name,value]of Object.entries(files))assert.equal(readFileSync(path.join(target,name),'utf8'),value);
 assert.throws(()=>restore(encrypted,target,pass));assert.throws(()=>pack(input,encrypted,pass));
 const wrong=path.join(root,'wrong');assert.throws(()=>restore(encrypted,wrong,randomBytes(32).toString('hex')));assert.equal(existsSync(wrong),false);
 bytes[bytes.length-1]^=1;const damaged=path.join(root,'tampered');writeFileSync(damaged,bytes);const out=path.join(root,'partial');assert.throws(()=>restore(damaged,out,pass));assert.equal(existsSync(out),false);
 }finally{assert.equal(path.dirname(path.resolve(root)),path.resolve(tmpdir()));assert.ok(path.basename(root).startsWith('atena-recovery-'));rmSync(root,{recursive:true,force:true});}
});
test('short passphrase and links rejected before backup',()=>{
 const root=mkdtempSync(path.join(tmpdir(),'atena-recovery-'));try{const input=path.join(root,'input');mkdirSync(input);writeFileSync(path.join(input,'fixture'),'TEST');assert.throws(()=>pack(input,path.join(root,'out'),'short'));
 const linked=path.join(root,'linked');symlinkSync(input,linked,'junction');assert.throws(()=>pack(linked,path.join(root,'out'),randomBytes(32).toString('hex')));
 }finally{assert.equal(path.dirname(path.resolve(root)),path.resolve(tmpdir()));assert.ok(path.basename(root).startsWith('atena-recovery-'));rmSync(root,{recursive:true,force:true});}
});
