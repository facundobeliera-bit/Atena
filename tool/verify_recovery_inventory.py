"""Offline consistency checks for an isolated FICTITIOUS recovery inventory.
No network, export, restore, SQL execution or secret values. Does not certify
Auth/Storage services: their real login and authorization tests remain mandatory.
Snapshots must be produced from the source/restored systems, not hand asserted.
"""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import uuid

DB_SECTIONS = {'rows', 'policies', 'grants', 'functions', 'indexes', 'sequences', 'constraints', 'triggers', 'rls'}

def validate(snapshot, root):
    if Path(root).is_symlink(): raise ValueError('Object root symlinks not allowed')
    root = Path(root).resolve(strict=True)
    if set(snapshot) != {'format','fixture_only','environment_id','postgres','auth_users','objects','profiles','enrollments','documents','configuration'}:
        raise ValueError('Unexpected inventory sections')
    if snapshot['format'] != 1 or snapshot['fixture_only'] is not True:
        raise ValueError('Only explicit fictitious inventories allowed')
    if not re.fullmatch(r'atena_disposable_[a-z0-9_]+', snapshot['environment_id']):
        raise ValueError('Isolated environment identifier required')
    db = snapshot['postgres']
    if set(db) != DB_SECTIONS or any(not isinstance(v, dict) or not v for v in db.values()):
        raise ValueError('Incomplete database evidence')
    # Fingerprints, never row contents, personal data, JWTs or password hashes.
    for section in db.values():
        for value in section.values():
            if not isinstance(value, str) or not re.fullmatch('[a-f0-9]{64}', value):
                raise ValueError('Expected SHA-256 fingerprints')
    users = snapshot['auth_users']
    if not isinstance(users, list) or not users or len(set(users)) != len(users):
        raise ValueError('Auth identity inventory required')
    for user in users:
        if str(uuid.UUID(user)) != user: raise ValueError('Invalid synthetic UUID')
    objects = snapshot['objects']
    for name, obj in objects.items():
        path = PurePosixPath(name)
        if not name or '\\' in name or ':' in name or path.is_absolute() or str(path)!=name or any(p in ('..','.') for p in name.split('/')):
            raise ValueError('Unsafe object path')
        if set(obj) != {'sha256','size','owner','private'} or obj['private'] is not True or obj['owner'] not in users:
            raise ValueError('Invalid private object ownership')
        current = root
        for part in path.parts:
            current = current / part
            if current.is_symlink(): raise ValueError('Object symlinks not allowed')
        resolved = current.resolve(strict=True)
        if not resolved.is_relative_to(root) or not resolved.is_file(): raise ValueError('Object outside isolated root')
        if resolved.stat().st_size != obj['size'] or hashlib.sha256(resolved.read_bytes()).hexdigest() != obj['sha256']:
            raise ValueError('Storage bytes differ')
    actual = set()
    for entry in root.rglob('*'):
        if entry.is_symlink(): raise ValueError('Object symlinks not allowed')
        if entry.is_file(): actual.add(entry.relative_to(root).as_posix())
    if actual != set(objects): raise ValueError('Storage inventory is incomplete')
    profiles = snapshot['profiles']
    if not profiles or any(not owners or len(set(owners)) != len(owners) or any(u not in users for u in owners) for owners in profiles.values()):
        raise ValueError('Profile/Auth dependency missing')
    if any(p not in profiles for p in snapshot['enrollments'].values()):
        raise ValueError('Enrollment/profile dependency missing')
    for doc in snapshot['documents'].values():
        if set(doc) != {'object','profile'} or doc['object'] not in objects or doc['profile'] not in profiles:
            raise ValueError('Document reference missing')
        if objects[doc['object']]['owner'] not in profiles[doc['profile']]:
            raise ValueError('Document ownership differs')
    config = snapshot['configuration']
    if set(config) != {'purge_enabled','outbound_mail_enabled','public_access_enabled','migrations_sha256','auth_config_sha256','storage_config_sha256'}:
        raise ValueError('Unexpected configuration evidence')
    if any(config[k] is not False for k in ('purge_enabled','outbound_mail_enabled','public_access_enabled')):
        raise ValueError('Destination must remain closed')
    if any(not re.fullmatch('[a-f0-9]{64}', config[k]) for k in ('migrations_sha256','auth_config_sha256','storage_config_sha256')):
        raise ValueError('Configuration fingerprints missing')

def compare(before, after, source_objects, restored_objects):
    if Path(source_objects).resolve() == Path(restored_objects).resolve():
        raise ValueError('Object roots must be independent')
    validate(before, source_objects)
    validate(after, restored_objects)
    if before['environment_id'] == after['environment_id']:
        raise ValueError('Restoration must use a different environment')
    if {k:v for k,v in before.items() if k!='environment_id'} != {k:v for k,v in after.items() if k!='environment_id'}:
        raise ValueError('Restored inventory differs')
    return {'inventory_consistent': True, 'storage_bytes_checked': len(after['objects']),
            'integral_restore_validated': False,
            'pending': ['real isolated Auth login', 'Storage authorization and expiry', 'new JWT isolation and revocation']}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('before','after','source_objects','restored_objects'): p.add_argument('--'+name.replace('_','-'),required=True,type=Path)
    a=p.parse_args()
    try:
        result=compare(json.loads(a.before.read_text(encoding='utf-8')),json.loads(a.after.read_text(encoding='utf-8')),a.source_objects,a.restored_objects)
    except (ValueError, OSError, TypeError, KeyError):
        raise SystemExit('FAIL: incomplete or inconsistent isolated inventory (values omitted)') from None
    print(json.dumps(result))

if __name__=='__main__': main()
