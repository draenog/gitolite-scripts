#!/bin/sh

[ "${GL_REPO#packages/}" = "$GL_REPO" ] && exit

check=$(basename "${GL_REPO}")
if [ -f $HOME/ignore ] && grep "^$check$" $HOME/ignore; then
    echo 'omitting push to github';
    exit;
fi
upstream=$(echo $check | tr + -)
git push -q --mirror ssh://git@github.com/pld-linux/$upstream
