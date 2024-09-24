#!/usr/bin/env bash
# Options
noop=false
prompt=true
lightweight=false
while getopts l,a,n,y,s: opt; do
    case $opt in
        a) lightweight=false;;
        l) lightweight=true;;
        n) noop=true;;
        s) stop=$OPTARG;;
        y) prompt=false;;
        :) exit 1;;
        *) exit 1;;
    esac
done

pattern='^v*\d+(\.\d+){1,}-?[a-z]*'

# Iterate oldest to newest.
orig_commits=$(git rev-list --reverse --no-commit-header --pretty='format:%H %s' --grep="$pattern" -P HEAD $([ "$stop" ] && echo "^$stop^"))
versions=$(echo "$orig_commits" | awk '{sub(/^v*/, "v", $2); print $2}')

echo "$orig_commits" | while read -r hash sub && read -r tag <&3; do
    # Still want msg set in dry-runs.
    if ! $lightweight; then
        msg=$(git rev-list --no-commit-header --no-walk --pretty='format:%B' $hash | sed '1s/^v*/v/')
    fi

    printf "%s: New tag %s  \t<- %s\n" $hash $tag "$sub"
    
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
        # Force will overwrite tags, i.e. the latest with version in commit message gets the tag.
    fi
done 3<<< "$versions"

# When first writing the commits, I got some of the versions wrong. Fix manually at this stage.
if $prompt; then
    read -p "Check everything is correct, fix mistakes, then PRESS ENTER to continue."
fi

git push --tags $($noop && echo -e "\x2dn")

# If $stop, use --contains. Performance impact due to how it traverses commit history, so only use then.
# This effectively only selects tags that were just created.
# Unless you point to commit with existing tag that doesn't match message pattern.

# We grab subject to set a consistent release title without relying on gh's default behavior.
# If lightweight, the default would screw us over because the format of the commit message doesn't match the tag.

# Filter to the version pattern with grep. Alternative is "refs/tags/v*" glob, but that's not regex and also grabs misc. tags starting with "v".
tags=$(git for-each-ref --format='%(refname:strip=2) %(subject)' $([ "$stop" ] && echo "--contains=$stop") refs/tags | grep -P "$pattern")
if $lightweight; then
    # If annotated, prefix is already fixed in tag message, but not for lightweight's commit message.
    # Could also use same awk as above but print $0.
    tags=$(echo "$tags" | sed -E 's/^(\w*\s+)v*/\1v/')
fi
echo "$tags" | while read -r tag sub; do
    if ! $noop; then
        gh release create $tag --notes-from-tag -t "$sub"
    fi
done