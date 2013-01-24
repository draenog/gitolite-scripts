#!/usr/bin/python3

import sys
import os
import json
import requests
import time

# github limits rate of requests to 5000 per 1h
maxwait = 3600./5000.

def check_repo(repo):
    with open(os.path.expanduser("~/ignore"), "r") as f:
        for line in f:
            if line.strip() == repo:
                return 1
    return 0

def github_sanitize(repo):
    return repo.replace('+','-')

def create_irchook(repo):
    ircconf = json.dumps({'name': 'irc',
                       'config' :
                            {'nick' : 'pldgit',
                             'room' : '#pld-git',
                             'server' : 'irc.freenode.org',
                             'long_url' : '1',
                             'message_without_join' : '1'}})
    return requests.post("https://api.github.com/repos/pld-linux/{}/hooks".format(repo), auth=logpass, data=ircconf)

def printhelp():
    print("""Usage: pldgithub.py create REPO [, REPO2 [, REPO3...]]
   or: pldgithub.py delete REPO [, REPO2 [, REPO3...]]
   or: pldgithub.py rename REPO NEWNAME
   or: pldgithub.py crthook REPO [, REPO2 [, REPO3...]]
   or: pldgithub.py description REPO 'New description'""")
    sys.exit(1)

if len(sys.argv) < 3 or sys.argv[1] not in ('create', 'delete', 'rename', 'description', 'crthook'):
    printhelp()
elif sys.argv[1] == 'rename' and len(sys.argv) != 4:
    printhelp()

logpass = tuple(open(os.path.expanduser('~/auth'), 'r').readline().strip().split(':'))

if sys.argv[1] == 'create':
    for newrepo in [repo.strip() for repo in sys.argv[2:]]:
        githubrepo = github_sanitize(newrepo)
        req = requests.post("https://api.github.com/orgs/pld-linux/repos", auth=logpass,
                data=json.dumps({'name': githubrepo, 'has_issues': False, 'has_wiki': False, 'has_downloads': False}))
        if not req.status_code == 201:
            sys.stderr.write("Cannot create {} on github\n".format(newrepo))
            continue
        req = create_irchook(githubrepo)
        if not req.status_code == 201:
            sys.stderr.write("Cannot create irc hook for {} on github\n".format(newrepo))
elif sys.argv[1] == 'delete':
    need_sleep = False
    for cannedrepo in [repo.strip() for repo in sys.argv[2:]]:
        if check_repo(cannedrepo):
            sys.stderr.write("Ignoring deletion of {} on github\n".format(cannedrepo))
            continue
        if need_sleep:
            time1=maxwait-(time.time()-time1)
            if time1 > 0:
                time.sleep(time1)
        time1 = time.time()
        req = requests.delete("https://api.github.com/repos/pld-linux/"+github_sanitize(cannedrepo), auth=logpass)
        need_sleep=True
        if not req.status_code == 204:
            sys.stderr.write("Cannot delete {} from github\n".format(cannedrepo))
elif sys.argv[1] == 'rename':
    (oldrepo, newrepo) = [arg.strip() for arg in sys.argv[2:4]]
    req = requests.patch("https://api.github.com/repos/pld-linux/"+github_sanitize(oldrepo), auth=logpass,
            data=json.dumps({'name': github_sanitize(newrepo)}))
    if not req.status_code == 200:
        raise SystemExit("Cannot rename {} to {} on github".format(oldrepo, newrepo))
elif sys.argv[1] == 'description':
    (repo, newdesc) = [arg.strip() for arg in sys.argv[2:4]]
    if check_repo(repo):
        raise SystemExit("Ignoring sending summary of {} to github".format(repo))
    req = requests.patch("https://api.github.com/repos/pld-linux/"+repo, auth=logpass,
            data=json.dumps({'name': repo, 'description': newdesc}))
    if not req.status_code == 200:
        raise SystemExit("Cannot change description for {} on github".format(repo))
elif sys.argv[1] == 'crthook':
    need_sleep = False
    for cannedrepo in [repo.strip() for repo in sys.argv[2:]]:
        if check_repo(cannedrepo):
            sys.stderr.write("Ignoring creating irc hook for {} on github\n".format(cannedrepo))
            continue
        if need_sleep:
            time1=maxwait-(time.time()-time1)
            if time1 > 0:
                time.sleep(time1)
        time1 = time.time()
        req = create_irchook(github_sanitize(cannedrepo))
        need_sleep=True
        if not (req.status_code == 200 or req.status_code==201):
            sys.stderr.write("Cannot create irc hook for {} on github\n".format(cannedrepo))

