#!/bin/sh

[ "${GL_REPO#packages/}" = "$GL_REPO" ] && exit

check=$(basename "${GL_REPO}").git
grep "^$check$" $HOME/ignore && { echo 'omitting push to github'; exit; }
upstream=$(echo $check | tr + -)
git push --mirror ssh://git@github.com/pld-linux/$upstream > /dev/null
