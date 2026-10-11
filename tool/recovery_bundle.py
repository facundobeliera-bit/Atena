"""Local encrypted bundle CLI with a hidden passphrase prompt; no remote access."""
import argparse,getpass,pathlib,subprocess
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('action',choices=['pack','restore']);p.add_argument('source');p.add_argument('target');a=p.parse_args()
password=getpass.getpass('Passphrase (20+ characters; not stored): ')
if a.action=='pack' and password!=getpass.getpass('Repeat passphrase: '):raise SystemExit('Passphrases differ')
try:
    result=subprocess.run(['node',str(pathlib.Path(__file__).with_suffix('.mjs')),a.action,a.source,a.target],input=password,text=True)
finally:password=None
raise SystemExit(result.returncode)
