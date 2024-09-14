# Commit2Release

Bash script to automate creating GitHub Releases based on commits that match a version pattern.

A long, long time ago, I created a project, [biscottiHUD](https://github.com/MedicodiBiscotti/biscottihud) before I knew that you were supposed to use atomic commits in Git, or what tags were. This was before I learned how to code properly. For years, I used commits as essentially releases containing massive file changes and multi-line messages with a version subject line and release notes body.

The version pattern I used was this: `1.2`, `1.2a`, `1.2b`, `1.3` etc. Instead of a patch version, I appended letters. Sadly, it's not [semver](https://semver.org/) but what's done is done.

Version commits can be searched for with this Regex pattern: `'^v?\d+(\.\d+){1,}-?[a-z]*'`. It also allows for more `.2.3` and a hyphen before letters, like `-alpha`.

Script works like this:

1. Search commits that match the version pattern.
2. Create tags on those commits using its version.
3. Push tags to GitHub.
4. Create GitHub releases based on those commits.

## Notes

Script runs through commits in chronological order and overwrites existing tags, meaning if you had multiple commits with same version, the latest (most recent) commit gets the tag.

Git lists tags in alphabetical order, so if your commits' versions are out of order, the releases will be too. Unfortunately, this also means `v1.2` comes before `v1.2-alpha`. We can also list in order of creation.

By default, the script pauses to let you inspect the tags it created and make sure everything is correct before continuing.

Annotated vs. lightweight might require some different strategies as lightweight doesn't have the same amount of data associated.

## Features

- [x] Basic functionality.
- [ ] Option to skip pause.
- [ ] Only process down to given commit.
- [ ] Option to use annotated/lightweight tags.
- [ ] More intelligent handling of release title.

## Requirements

- `git`
- `gh` [GitHub CLI](https://cli.github.com/)
