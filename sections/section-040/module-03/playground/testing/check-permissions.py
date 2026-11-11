import json,subprocess,sys
from pathlib import Path

def get(*args):
    return json.loads(subprocess.check_output(['kubectl',*args,'-o','json'],text=True))
def check(ok,msg):
    if not ok: sys.exit('FAIL: '+msg)
def access(user,verb,resource,namespace,expected):
    p=subprocess.run(['kubectl','auth','can-i',verb,resource,'-n',namespace,'--as='+user],text=True,capture_output=True)
    if p.returncode not in (0,1) or p.stdout.strip() not in ('yes','no'):
        raise RuntimeError(p.stderr or p.stdout)
    check((p.stdout.strip()=='yes')==expected,f'{user}: {verb} {resource} in {namespace} must be {expected}')
# Existing bindings remain the only route to the built-in roles.
original=json.loads((Path(__file__).resolve().parent/'bindings.json').read_text())
for old in original['items']:
    new=get('-n','outpost','get','rolebinding',old['metadata']['name'])
    check(new['metadata']['uid']==old['metadata']['uid'] and new['roleRef']==old['roleRef'] and new['subjects']==old['subjects'],'preserve the existing bindings')
roles=get('get','clusterroles')['items']
for role,verbs in [('edit',{'create','get','list','watch','update','patch','delete'}),('view',{'get','list','watch'})]:
    check(any(r.get('aggregationRule') for r in roles if r['metadata']['name']==role),'keep built-in aggregation')
    candidates=[r for r in roles if r['metadata'].get('labels',{}).get('rbac.authorization.k8s.io/aggregate-to-'+role)=='true']
    covered=set()
    for r in candidates:
        for rule in r.get('rules',[]):
            if 'platform.starfleet.io' in rule.get('apiGroups',[]):
                check(rule['apiGroups']==['platform.starfleet.io'] and rule.get('resources')==['teamenvironments'] and set(rule['verbs'])<=verbs,'aggregation must only add the stated platform API rights')
                covered.update(rule['verbs'])
    check(covered==verbs,f'add labelled ClusterRoles for {role}')
for verb in ('get','list','watch','create','update','patch','delete'):
    access('platform-editor',verb,'teamenvironments.platform.starfleet.io','outpost',True)
    access('platform-reader',verb,'teamenvironments.platform.starfleet.io','outpost',verb in ('get','list','watch'))
    for user in ('platform-editor','platform-reader'):
        access(user,verb,'teamenvironments.platform.starfleet.io','starfleet',False)
access('platform-reader','get','secrets','outpost',False)
for user in ('platform-editor','platform-reader'):
    access(user,'create','rolebindings','outpost',False)
print('PASS: aggregated editor and reader permissions preserve write and namespace boundaries')
