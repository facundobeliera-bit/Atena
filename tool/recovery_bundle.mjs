/** Offline envelope for isolated recovery rehearsals. Never contacts Supabase.
 * Node built-in crypto: scrypt N=65536,r=8,p=1 + AES-256-GCM; entire manifest authenticated.
 * Bound to 256 MiB: larger production backups require a reviewed streaming backup tool.
 */
import {scryptSync,randomBytes,createCipheriv,createDecipheriv,createHash} from 'node:crypto';
import {readFileSync,writeFileSync,readdirSync,lstatSync,mkdirSync,existsSync,renameSync,rmSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const MAGIC=Buffer.from('ATENA-BACKUP-1\n'),MAX=256*1024*1024;
const digest=b=>createHash('sha256').update(b).digest('hex');
function key(password,salt){if(typeof password!=='string'||password.length<20)throw Error('Passphrase must contain at least 20 characters');return scryptSync(password,salt,32,{N:65536,r:8,p:1,maxmem:128*1024*1024});}
function relative(name){return typeof name==='string'&&name.length>0&&!name.includes('\\')&&!name.includes(':')&&!name.startsWith('/')&&name.split('/').every(p=>p!==''&&p!=='.'&&p!=='..');}
export function pack(source,destination,password){
 if(existsSync(destination))throw Error('Never overwrite an existing backup');
 if(lstatSync(source).isSymbolicLink()||!lstatSync(source).isDirectory())throw Error('Expected a real source directory');
 const files=[];let total=0;
 function walk(dir,prefix=''){for(const name of readdirSync(dir).sort()){
 const full=path.join(dir,name),entry=prefix+name,stat=lstatSync(full);
 if(stat.isSymbolicLink())throw Error('Links are not allowed');
 if(stat.isDirectory())walk(full,entry+'/');else if(stat.isFile()){
 if(!relative(entry)||(total+=stat.size)>MAX)throw Error('Unsafe name or backup exceeds 256 MiB');
 const bytes=readFileSync(full);files.push({name:entry,size:bytes.length,sha256:digest(bytes),content:bytes.toString('base64')});
 }else throw Error('Unsupported entry');}}
 walk(source);if(!files.length)throw Error('Empty backup');
 const salt=randomBytes(32),iv=randomBytes(12),k=key(password,salt);
 const header=Buffer.concat([MAGIC,salt,iv]),cipher=createCipheriv('aes-256-gcm',k,iv);cipher.setAAD(header);
 const plain=Buffer.from(JSON.stringify({format:1,files}));
 try{const data=Buffer.concat([cipher.update(plain),cipher.final()]);writeFileSync(destination,Buffer.concat([header,cipher.getAuthTag(),data]),{flag:'wx',mode:0o600});}
 finally{k.fill(0);plain.fill(0);}
 return {files:files.length,bytes:total,sha256:digest(readFileSync(destination))};
}
export function restore(source,target,password){
 if(existsSync(target))throw Error('Restore target must not exist');
 const size=lstatSync(source).size;if(size>MAX*1.5||size<MAGIC.length+60)throw Error('Invalid envelope size');
 const input=readFileSync(source);if(!input.subarray(0,MAGIC.length).equals(MAGIC))throw Error('Unknown backup format');
 const end=MAGIC.length+44,salt=input.subarray(MAGIC.length,MAGIC.length+32),iv=input.subarray(MAGIC.length+32,end),k=key(password,salt);
 let plain;try{const cipher=createDecipheriv('aes-256-gcm',k,iv);cipher.setAAD(input.subarray(0,end));cipher.setAuthTag(input.subarray(end,end+16));plain=Buffer.concat([cipher.update(input.subarray(end+16)),cipher.final()]);}finally{k.fill(0);}
 let bundle;try{bundle=JSON.parse(plain.toString('utf8'));}finally{plain.fill(0);}
 if(bundle.format!==1||!Array.isArray(bundle.files)||!bundle.files.length)throw Error('Invalid manifest');
 const seen=new Set();let total=0;const entries=bundle.files.map(f=>{
 if(!relative(f.name)||seen.has(f.name.toLowerCase()))throw Error('Unsafe or duplicate path');seen.add(f.name.toLowerCase());
 const data=Buffer.from(f.content,'base64');if(data.length!==f.size||digest(data)!==f.sha256||(total+=data.length)>MAX)throw Error('Integrity check failed');
 return [f.name,data];});
 // No file is exposed until authentication and all checks have passed.
 const parent=path.dirname(path.resolve(target));if(!existsSync(parent))throw Error('Target parent must already exist');
 const temp=path.join(parent,'.atena-restore-'+randomBytes(12).toString('hex'));mkdirSync(temp,{mode:0o700});
 try{for(const [name,data]of entries){const file=path.join(temp,...name.split('/'));mkdirSync(path.dirname(file),{recursive:true,mode:0o700});writeFileSync(file,data,{flag:'wx',mode:0o600});}if(existsSync(target))throw Error('Target appeared during restore');renameSync(temp,target);}
 catch(error){if(path.dirname(path.resolve(temp))!==parent||!path.basename(temp).startsWith('.atena-restore-'))throw Error('Unsafe temporary cleanup path');rmSync(temp,{recursive:true,force:true});throw error;}
 return {files:entries.length,bytes:total};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{const [action,source,target]=process.argv.slice(2);if(!['pack','restore'].includes(action)||!source||!target)throw Error('Usage: node recovery_bundle.mjs pack|restore SOURCE TARGET (passphrase via stdin only)');
 const password=readFileSync(0,'utf8').replace(/\r?\n$/,'');const result=(action==='pack'?pack:restore)(source,target,password);process.stdout.write(JSON.stringify(result)+'\n');}
 catch{process.stderr.write('Recovery operation failed; no successful restore is claimed. Check paths, passphrase and envelope integrity.\n');process.exitCode=1;}
}
