# Commit2Release

Bash script to automate creating GitHub Releases based on commits that match a version pattern.

A long, long time ago, I created a project, [biscottiHUD](https://github.com/MedicodiBiscotti/biscottihud) before I knew that you were supposed to use atomic commits in Git, or what tags were. This was before I learned how to code properly. For years, I used commits as essentially releases containing massive file changes and multi-line messages with a version subject line and release notes body.

The version pattern I used was this: `1.2`, `1.2a`, `1.2b`, `1.3` etc. Instead of a patch version, I appended letters. Sadly, it's not [semver](https://semver.org/) but what's done is done.

Version commits can be searched for with this Regex pattern: `'^v*\d+(\.\d+){1,}-?[a-z]*'`. It also allows for `v` prefix (several in case of typo), more `.2.3`, and a hyphen before letters, like `-alpha`.

Script works like this:

1. Search commits that match the version pattern.
2. Create tags on those commits using its version.
3. Push tags to GitHub.
4. Create GitHub releases based on those commits.

## Notes

Script runs through commits in chronological order and overwrites existing tags, meaning if you had multiple commits with same version, the latest (most recent) commit gets the tag.

Git lists tags in alphabetical order, so if your commits' versions are out of order, the releases will be too. Unfortunately, this also means `v1.2` comes before `v1.2-alpha`. We can also list in order of creation.

By default, the script pauses to let you inspect the tags it created and make sure everything is correct before continuing. One thing to fix is tag names or which commits are tagged. Another is the tag message if annotated. Editing a tag in place is not possible, but this alias is a close approximation. It creates a new tag with the message of the old one, opening it in the default text editor for you to edit further.

```
te = !git tag -l --format='%(contents)' $1 | git tag -aefF - $1 $1^{} && :
```

Another useful one is to rename a tag. Be careful about naming it to its existing name as it will delete the old tag at the end (which is the same as the new one in this case).

```
tr = !git tag -l --format='%(contents)' $1 | git tag -aF - $2 $1^{} && git tag -d $1 && :
```

_I would've put the `git config` commands, but I couldn't figure out how to escape the right things so it would show up in config like above._

If script outputs `Updated tag '<version> (was <hash>)` then it overwrote an existing tag. It's possible that you have multiple commits with the same version which needs fixing. If using annotated tags and rerunning the script, this will always be the case as it creates a new object every time, so it's less indicative then.

The pause also allows you to exit out with `CTRL+C` if you don't want to continue. This behavior could change in the future to a `Y/n` prompt.

Remember, **this is destructive**. It will delete the existing tag and create a new one. Probably don't use this on tags that have been pushed and/or have releases based on them.

Annotated vs. lightweight might require some different strategies as lightweight doesn't have the same amount of data associated.

Annotated tags is the default and `-a` takes precedence over `-l` if both are supplied.

Dry-run will also push as a dry-run. If the tags exist locally, it will output as if pushed to remote. If the tags don't exist locally because they weren't created during the dry-run, then it will likely just show `Everything up-to-date`.

Stopping at specified commit works by using `rev-list HEAD ^<commit-ish>^` and `for-each-ref --contains=<commit-ish>`. These commands work in opposite directions, so to get them to include the same commit, `rev-list` has to look at the parent which is then excluded along with its parents, but the child (our target) and later history is included. `--contains` looks for descendants while `rev-list` looks for ancestors which are opposite operations, and both exclude the target in their exclusion modes, leading to "off-by-1" errors when using both together. So `rev-list` has to look at target's parent so that the target is not excluded.

As far as I understand, `--contains` loops all refs and traverses each ones whole history to see if it ever includes the target. This is due to the directionality of commits having a parent chain but no access to its direct children. For large repos with many refs and long histories, this is potentially computationally expensive. This is only used when necessary when limiting commit traversal to only create releases for the tags just created.

## Features

- [x] Basic functionality.
- [x] Option to skip pause (`-y`).
- [x] Option to dry-run (`-n`).
- [x] Option to use annotated/lightweight tags (`-a`/`-l`).
- [x] Only process down to given commit (`-s`).
- [x] More intelligent handling of release title.

## Requirements

- `git`
- `gh` [GitHub CLI](https://cli.github.com/)

## Things I learned

Just a little list of things I learned over the course of making this script.

- Shell scripting
- Bashisms
- Unix CLI text processing tools
  - `awk`
  - `sed`
  - `cut`
- Git internal plumbing commands
  - `rev-list`
  - `for-each-ref`
  - Format syntax to select specific data about the objects.
- Default behavior for GitHub release title generation based on contents of text body.
