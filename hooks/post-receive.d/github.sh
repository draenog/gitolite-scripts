#!/bin/sh

[ "${GL_REPO#packages/}" = "$GL_REPO" ] && exit

upstream=$(basename "${GL_REPO}").git
grep "^$upstream$" $HOME/ignore && { echo 'omitting push to github'; exit; }
git push --mirror ssh://git@github.com/pld-linux/$upstream > /dev/null
