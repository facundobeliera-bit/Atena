"""Prepare administrative RPC operations. Default is read-only planning; no credentials in arguments.
Execution requires separate remote authorization. Never edits tables directly.
"""
import argparse,getpass,json,urllib.request,urllib.error,uuid
PROJECT='eaegvxxxkvhdukbkydvy'
def plan(user,active,scope='institution'):
    if scope not in ('institution','family'):raise ValueError('Unknown review scope')
    user=str(uuid.UUID(user))
    return {'project':PROJECT,'rpc':'atena_family_reviewer' if scope=='family' else 'atena_onboarding_reviewer','parameters':{'p_user':user,'p_active':active},'requires':'trusted administrative credential; separate remote authorization'}
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--reviewer-user',required=True)
    p.add_argument('--disable',action='store_true')
    p.add_argument('--scope',choices=['institution','family'],default='institution')
    p.add_argument('--execute-authorized-pilot',choices=[PROJECT])
    a=p.parse_args();operation=plan(a.reviewer_user,not a.disable,a.scope)
    if not a.execute_authorized_pilot:
        print(json.dumps(operation,indent=2));return
    credential=getpass.getpass('Administrative API credential (memory only): ')
    headers={'apikey':credential,'Content-Type':'application/json'}
    # Modern secret API keys are API keys, not JWT bearer tokens.
    if credential.count('.')==2:headers['Authorization']='Bearer '+credential
    req=urllib.request.Request(f'https://{PROJECT}.supabase.co/rest/v1/rpc/'+operation['rpc'],data=json.dumps(operation['parameters']).encode(),headers=headers,method='POST')
    try:
        with urllib.request.urlopen(req,timeout=30) as response:
            if response.status not in (200,204):raise RuntimeError('Unexpected status')
        print('Administrative RPC confirmed. No Auth account or password changed.')
    except (urllib.error.URLError,RuntimeError):
        raise SystemExit('Operation not confirmed. Inspect server state before retrying; no credentials or response payload logged.')
    finally:credential=None
if __name__=='__main__':main()
