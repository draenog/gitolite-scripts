#!/bin/sh

die() { echo "$@"; exit 1; }

export GIT_WORK_TREE=$(git config hooks.specsdir)
[ -d "$GIT_WORK_TREE" ] || die "GIT_WORK_TREE not exist"

export GIT_DIR=$(git config hooks.specsrepo)
[ -d "$GIT_DIR" ] || die "SPECS repo not defined"

lockfile="$GIT_DIR"/gc.pid
[ -f $lockfile ] && exit 0
echo "$$ $(hostname -s)" > $lockfile
status=$(git status --porcelain)
if [ -n "$status" ]; then
    git add -A .
    git commit -m "SPECS updated `date`"
fi
rm $lockfile
