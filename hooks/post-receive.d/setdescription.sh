#!/bin/sh

repo=${GL_REPO#packages/}
[ "$repo" = "$GL_REPO" ] && exit

SPECSDIR=$(git config hooks.specsdir)
[ -n "${SPECSDIR%%/*}" ] &&  SPECSDIR="$HOME/$SPECSDIR"
[ -d $SPECSDIR ] || echo "SPECSDIR $SPECSDIR is missing"

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
                [ -f description ] && description=`cat description`
                [ -z "$summary" ] && echo "Missing Summary in spec file $file"
                if [ -n "$summary" -a "$summary" != "$description" ]; then
                    echo "$summary" > description
                    ~/bin/pldgithub.py description "$repo" "$summary"
                fi
                [ -d $SPECSDIR ] && git --work-tree="$SPECSDIR" checkout -f  $newsha1 "$file"
            else
                [ -d $SPECSDIR ] && rm --interactive=never "$SPECSDIR/$file"
            fi
        done
done
