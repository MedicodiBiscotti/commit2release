#!/usr/bin/env bash
# Options
noop=false
prompt=true
lightweight=false
while getopts l,a,n,y opt; do
    case $opt in
        a) lightweight=false;;
        l) lightweight=true;;
        n) noop=true;;
        y) prompt=false;;
    esac
done

pattern='^v*\d+(\.\d+){1,}-?[a-z]*'

# Iterate oldest to newest
git rev-list --reverse --no-commit-header --pretty='format:%H %s' --grep=$pattern -P HEAD | while read -r hash version rest; do
    tag=$(echo "$version" | sed '1s/^v*/v/')

    # Still want msg set in dry-runs.
    if ! $lightweight; then
        msg=$(git rev-list --no-commit-header --no-walk --pretty='format:%B' $hash | sed '1s/^v*/v/')
    fi

    printf "%s: New tag %s  \t<- %s %s\n" $hash $tag $version "$rest"
    
    if ! $noop; then
        # Really annoying that the tag command won't play nice both being lightweight and not.
        # Subbing in options just doesn't give the right amount of argument in both cases.
        # Something with the variable expansion and quotes gives too many arguments. Tried many ways, just won't work.
        # eval works with storing command in variable but is spooky and insecure.
        if ! $lightweight; then
            git tag -f -m "$msg" $tag $hash
        else
            git tag -f $tag $hash
        fi
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
# Could do different format (not get subject and not fix prefix) unless it's lightweight
# This works fine, is simple, and doesn't rely on gh's default behaviour for reliable titles.
# Would *barely* make a performance difference.
git for-each-ref --format='%(refname:strip=2) %(subject)' refs/tags | while read -r tag sub; do
    # Prefixes version subject with v for the title.
    # If annotated tag, this has already been done, but not on lightweight.
    sub=$(echo "$sub" | sed '1s/^v*/v/')
    gh release create $tag --notes-from-tag -t "$sub"
done