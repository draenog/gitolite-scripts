#!/bin/sh

die() { echo "$@"; exit 1; }

export GIT_WORK_TREE=$(git config hooks.specsdir)
[ -d "$GIT_WORK_TREE" ] || die "GIT_WORK_TREE not exist"

export GIT_DIR=$(git config hooks.specsrepo)
[ -d "$GIT_DIR" ] || die "SPECS repo not defined"

status=$(git status --porcelain)
if [ -n "$status" ]; then
    git add .
    git commit -m "SPECS updated `date`"
fi
