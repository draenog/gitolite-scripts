#!/usr/bin/python3

import sys
import os
import json
import requests

if len(sys.argv) < 3 or sys.argv[1] not in ('create', 'delete'):
    print("""Usage: pldgithub.py create REPO [, REPO2 [, REPO3...]]
   or: pldgithub.py delete REPO [, REPO2 [, REPO3...]]""")
    sys.exit(1)

logpass = tuple(open(os.path.expanduser('~/auth'), 'r').readline().strip().split(':'))

if sys.argv[1] == 'create':
    for newrepo in sys.argv[2:]:
        req = requests.post("https://api.github.com/orgs/pld-linux/repos", auth=logpass, data=json.dumps({'name': newrepo}))
        if not req.status_code == 201:
            raise SystemExit("Cannot create repository {} on github".format(newrepo))
else:
    for cannedrepo in sys.argv[2:]:
        req = requests.delete("https://api.github.com/repos/pld-linux/"+cannedrepo, auth=logpass)
        if not req.status_code == 204:
            raise SystemExit("Cannot delete repository {} from github".format(cannedrepo))


