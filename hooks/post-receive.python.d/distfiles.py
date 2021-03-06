import configparser
import os
import subprocess
from git_slug.gitconst import EMPTYSHA1

MAILFROMHOST = 'pld-linux.org'
MAILCOMMAND = '/usr/sbin/sendmail -t'.split()


def readconfig():
    config = configparser.ConfigParser(delimiters='=', interpolation=None, strict=False)
    config.read(os.path.expanduser('~/.gitconfig'))
    return config.get('hooks', 'distfiles', fallback=None)

def distfiles_notification(login, package, branch):
    DISTFILES_EMAIL = readconfig()
    if DISTFILES_EMAIL is None:
        return
    mailprocess = subprocess.Popen(MAILCOMMAND, stdin=subprocess.PIPE)
    mailprocess.stdin.write(
"""To: {distfiles_email}
From: {login} <{login}@{MAILFROMHOST}>
Subject: cvs to df notify
X-distfiles-request: yes
X-Login: {login}
X-Package: {package}
X-Branch: {branch}
X-Flags: git-notify
""".format(distfiles_email=DISTFILES_EMAIL,
           login = login,
           MAILFROMHOST = MAILFROMHOST,
           package = package,
           branch = branch).encode('utf-8')
        )
    mailprocess.communicate()

def run(data):
    gitrepo = os.environ.get('GL_REPO')
    if gitrepo.startswith('packages/'):
        gitrepo = gitrepo[len('packages/'):]
    else:
        return
    for line in data:
        (sha1old, sha1, ref) = line.split()
        if ref.startswith('refs/heads/') and sha1 != EMPTYSHA1:
            distfiles_notification(os.getenv('GL_USER'), gitrepo, ref)
