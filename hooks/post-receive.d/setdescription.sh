#!/bin/sh

[ "${GL_REPO#packages/}" = "$GL_REPO" ] && exit

while read oldsha1 newsha1 ref; do
    [ "$ref" = "refs/heads/master" ] || continue
    specfile=`git ls-tree --name-only $newsha1 | grep '.spec$'`
    noline=`echo $specfile | wc -l`;
    if [ -z "$specfile" -o $noline -ne 1 ]; then
            echo "Problem with specfile"
            exit
    fi
    summary=`git cat-file -p $newsha1:$specfile | grep -m 1 '^Summary:' \
        | sed 's/Summary:[ \t]\+//'`
    [ -n "$summary" ] && echo "$summary" > description || echo "Missing Summary in spec file"
    break
done
