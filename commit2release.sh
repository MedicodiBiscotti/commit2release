#!/usr/bin/env bash
# Options
noop=false
prompt=true
while getopts n,y opt; do
    case $opt in
        n) noop=true;;
        y) prompt=false;;
    esac
done

pattern='^v*\d+(\.\d+){1,}-?[a-z]*'

# Iterate oldest to newest
git rev-list --reverse --no-commit-header --pretty='format:%H %s' --grep=$pattern -P HEAD | while read -r hash version rest; do
    tag=$(echo "$version" | sed 's/^v*/v/')
    printf "%s: New tag %s  \t<- %s %s\n" $hash $tag $version "$rest"
    if ! $noop; then
        git tag -f $tag $hash
    fi
done
# Force will overwrite tags, i.e. the latest with version in commit message gets the tag.

# When first writing the commits, I got some of the versions wrong. Fix manually at this stage.
if $prompt; then
    read -p "Check everything is correct, fix mistakes, then PRESS ENTER to continue."
fi

git push --tags $($noop && echo -e "\x2dn")

if $noop; then
    exit
fi

# Would be nice if we could grab only the newly created tags.
git tag --list | while read -r tag; do
    gh release create $tag --notes-from-tag
done