#!/bin/sh

[ "${GL_REPO#packages/}" = "$GL_REPO" ] && exit

empty_tree='4b825dc642cb6eb9a060e54bf8d69288fbee4904'

while read oldsha1 newsha1 ref; do
    [ "$ref" = "refs/heads/master" ] || continue
    export nospecs=0
    [ $oldsha1 = '0000000000000000000000000000000000000000' ] && oldsha1=$empty_tree
    git diff-tree --name-status $oldsha1 $newsha1 |
        while read change file; do
            [[ $file = *.spec ]] || continue
            if [ $change != D ]; then
                summary=`git cat-file -p $newsha1:$file | grep -m 1 '^Summary:' \
                    | sed 's/Summary:[ \t]\+//'`
                [ -n "$summary" ] && echo "$summary" > description || echo "Missing Summary in spec file $file"
            fi
        done
done
