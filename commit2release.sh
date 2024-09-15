#!/usr/bin/env bash
# Options
prompt=true;
while getopts y opt; do
    case $opt in
        y) prompt=false;;
    esac
done

pattern='^v*\d+(\.\d+){1,}-?[a-z]*'

# Iterate oldest to newest
git rev-list --reverse --no-commit-header --pretty='format:%H %s' --grep=$pattern -P HEAD | while read -r hash version rest; do
    printf "%s: %s\t  ...\tCreating tag: %s\n" $hash $version $tag;
    tag=$(echo "$version" | sed 's/^v*/v/')
    git tag -f $tag $hash;
done
# Force will overwrite tags, i.e. the latest with version in commit message gets the tag.

# When first writing the commits, I got some of the versions wrong. Fix manually at this stage.
if $prompt; then
    read -p "Check everything is correct, fix mistakes, then PRESS ENTER to continue."
fi

git push --tags

# Would be nice if we could grab only the newly created tags.
git tag --list | while read -r tag; do
    gh release create $tag --notes-from-tag
done