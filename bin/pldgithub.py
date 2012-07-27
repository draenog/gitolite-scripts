#!/usr/bin/python3

import sys
import os
import json
import requests

if len(sys.argv) < 3 or sys.argv[1] not in ('create', 'delete', 'description'):
    print("""Usage: pldgithub.py create REPO [, REPO2 [, REPO3...]]
   or: pldgithub.py delete REPO [, REPO2 [, REPO3...]]
   or: pldgithub.py description REPO 'New description'""")
    sys.exit(1)

logpass = tuple(open(os.path.expanduser('~/auth'), 'r').readline().strip().split(':'))

if sys.argv[1] == 'create':
    for newrepo in [repo.strip() for repo in sys.argv[2:]]:
        req = requests.post("https://api.github.com/orgs/pld-linux/repos", auth=logpass,
                data=json.dumps({'name': newrepo, 'has_issues': False, 'has_wiki': False, 'has_downloads': False}))
        if not req.status_code == 201:
            raise SystemExit("Cannot create repository {} on github".format(newrepo))
elif sys.argv[1] == 'delete':
    for cannedrepo in [repo.strip() for repo in sys.argv[2:]]:
        req = requests.delete("https://api.github.com/repos/pld-linux/"+cannedrepo, auth=logpass)
        if not req.status_code == 204:
            raise SystemExit("Cannot delete repository {} from github".format(cannedrepo))
else:
    (repo, newdesc) = [arg.strip() for arg in sys.argv[2:4]]
    req = requests.patch("https://api.github.com/repos/pld-linux/"+repo, auth=logpass,
            data=json.dumps({'name': repo, 'description': newdesc}))
    if not req.status_code == 200:
        raise SystemExit("Cannot change description for repository {} on github".format(repo))

