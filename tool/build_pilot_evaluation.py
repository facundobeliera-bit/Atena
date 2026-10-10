"""Build the existing PILOT only. No deploy, signing changes or remote writes."""
import argparse, hashlib, json, os, pathlib, re, shutil, subprocess, zipfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
PROJECT = 'eaegvxxxkvhdukbkydvy'
FLUTTER_REVISION = '19074d12f7eaf6a8180cd4036a430c1d76de904e'
ALLOWED = {'ATENA_REMOTE_ENV', 'ATENA_MULTIUSER', 'ATENA_SUPABASE_URL', 'ATENA_SUPABASE_PUBLISHABLE_KEY'}

def validate_config(value):
    if not isinstance(value, dict) or set(value) != ALLOWED:
        raise ValueError('Use exactly the four public pilot build settings; extra settings refused.')
    if value['ATENA_REMOTE_ENV'] != 'staging' or not (value['ATENA_MULTIUSER'] is True or value['ATENA_MULTIUSER'] == 'true'):
        raise ValueError('This builder accepts only the explicit multiuser staging environment.')
    if value['ATENA_SUPABASE_URL'] != f'https://{PROJECT}.supabase.co':
        raise ValueError('Unexpected pilot project.')
    key = value['ATENA_SUPABASE_PUBLISHABLE_KEY']
    if not isinstance(key, str) or not re.fullmatch(r'sb_publishable_[A-Za-z0-9_-]{10,}', key):
        raise ValueError('Only a public publishable key is accepted; privileged keys/JWTs refused.')
    return value

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def run(args, env=None):
    return subprocess.run([str(a) for a in args], cwd=ROOT, env=env, check=True)

def output(args):
    return subprocess.check_output([str(a) for a in args], cwd=ROOT).decode('utf-8-sig')

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--config', required=True, type=pathlib.Path)
    p.add_argument('--flutter', default='flutter')
    a = p.parse_args()
    config = validate_config(json.loads(a.config.read_text(encoding='utf-8-sig')))
    flutter = shutil.which(a.flutter)
    if not flutter:
        raise RuntimeError('Flutter executable unavailable.')
    version = json.loads(output([flutter, '--version', '--machine']))
    if version['frameworkRevision'] != FLUTTER_REVISION:
        raise RuntimeError('Use validated Flutter 3.38.3 revision ' + FLUTTER_REVISION)
    lock = ROOT / 'pubspec.lock'
    before = sha(lock)
    run([flutter, 'pub', 'get', '--enforce-lockfile'])
    if sha(lock) != before:
        raise RuntimeError('Lockfile changed unexpectedly; stop and inspect without discarding it.')
    env = dict(os.environ, ATENA_ANDROID_MULTIUSER='1', ATENA_ANDROID_DEMO='0')
    defines = '--dart-define-from-file=' + str(a.config.resolve())
    # Never clean the workspace or replace protected/untracked artifacts.
    run([flutter, 'build', 'web', '--release', '--no-pub', defines], env)
    run([flutter, 'build', 'apk', '--release', '--no-pub', defines], env)
    apk = ROOT / 'build/app/outputs/flutter-apk/app-release.apk'
    sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    if not sdk:
        for line in (ROOT / 'android/local.properties').read_text().splitlines():
            if line.startswith('sdk.dir='):
                sdk = line.split('=', 1)[1].replace('\\\\', '\\').replace('\\:', ':')
    tools = sorted(pathlib.Path(sdk or '').glob('build-tools/*/aapt.exe'))
    if not tools:
        raise RuntimeError('aapt unavailable: cannot certify Android application identity.')
    badging = output([tools[-1], 'dump', 'badging', apk])
    if "package: name='org.atena.evaluation.multiuser'" not in badging or "application-label:'Atena Multiusuario'" not in badging:
        raise RuntimeError('Unexpected APK application identity; evaluation copy refused.')
    doctor = output([flutter, 'doctor', '-v'])
    java_path = re.search(r'Java binary at: ([^\r\n]+)', doctor)
    if not java_path:
        raise RuntimeError('Flutter Java runtime unavailable.')
    java = pathlib.Path(java_path.group(1).strip())
    if os.name == 'nt' and java.suffix != '.exe':
        java = java.with_suffix('.exe')
    signer = tools[-1].parent / 'lib/apksigner.jar'
    signing = output([java, '-jar', signer, 'verify', '--print-certs', apk])
    dest = ROOT / 'build/evaluation'
    dest.mkdir(parents=True, exist_ok=True)
    final = dest / 'atena-v1-piloto-evaluacion.apk'
    shutil.copy2(apk, final)
    web = ROOT / 'build/web'
    archive = dest / 'atena-v1-piloto-web.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for f in sorted(web.rglob('*')):
            if f.is_file():
                z.write(f, f.relative_to(web).as_posix())
    files = output(['git', 'ls-files', '-z']).split('\0')
    source_hash = hashlib.sha256()
    for name in sorted(n for n in files if n and (ROOT / n).is_file()):
        source_hash.update(name.encode()); source_hash.update((ROOT / name).read_bytes())
    manifest = {
        'purpose': 'PRIVATE PILOT EVALUATION ONLY; not production; no deployment',
        'project': PROJECT, 'environment': config['ATENA_REMOTE_ENV'],
        'application_id': 'org.atena.evaluation.multiuser',
        'head': output(['git', 'rev-parse', 'HEAD']).strip(),
        'tracked_diff_names': output(['git', 'diff', 'HEAD', '--name-only']).splitlines(),
        'tracked_sources_sha256': source_hash.hexdigest(),
        'flutter_revision': version['frameworkRevision'], 'dart': version['dartSdkVersion'],
        'pubspec_lock_sha256': before,
        'android_build_tools': tools[-1].parent.name,
        'java_runtime': subprocess.run([str(java), '-version'], capture_output=True, text=True, check=True).stderr.splitlines()[0],
        'public_config_sha256': hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest(),
        'apk_sha256': sha(final), 'web_zip_sha256': sha(archive),
        'web_files': {f.relative_to(web).as_posix(): sha(f) for f in sorted(web.rglob('*')) if f.is_file()},
        'android_signer_sha256': next(x.split(': ', 1)[1] for x in signing.splitlines() if 'certificate SHA-256 digest:' in x),
        'signing_note': 'Existing development certificate; preserve it for private updates. Production signing is not configured.',
        'reproducibility': 'Pinned source/config/dependencies/toolchain. Binary-identical output across machines is not asserted.',
    }
    (dest / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    print('PASS pilot Android/web artifacts; manifest: ' + str(dest / 'manifest.json'))

if __name__ == '__main__':
    main()
