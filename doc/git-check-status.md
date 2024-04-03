# git-update-suggester Help Page

*Under Construction*


## Overview

`git-update-suggester` is a Bourne shell script that analyzes the current state of a git repository to suggest a series of `git` and GitHub (`gh`) commands. These suggestions aim to update the repository based on it's current state, including stashing, staging modifications, committing, fetching, merging, and releasing.

The script performs a series of checks to determine necessary actions, such as unstashing changes, staging and committing modifications, fetching and merging updates from the remote repository, and suggesting the next release number based on semantic versioning.

## Usage

```bash
git-update-suggester [ --help ]
```

## Overview

`git-update-suggester` is a shell script designed to automate and suggest git operations based on the current repository state. It intelligently analyzes your git repo to propose actions for updating and maintaining your codebase effectively.

## Features

- **Unstash Changes**: Automatically suggests unstashing saved changes if any stashes are detected.
- **Stage Modifications**: Identifies and stages all current modifications for commit.
- **Fetch Updates**: Fetches updates from the remote repository for the current branch if its behind.
- **Commit Changes**: Prepares commits for staged modifications with customizable commit messages.
- **Merge Branches**: Suggests merging the current branch with its upstream counterpart when necessary.
- **Release Management**: Helps in determining the next release version and suggests creating a release tag.

## Usage

Simply execute the script within your git repository:

```bash
./git-update-suggester.sh
```

## Example output

```bash
$ git-check-status.sh 

git stash list
Popping stash: stash@{0}
  - git stash pop 'stash@{0}'

git diff --name-only
Staging modified file: README.md
  - git add 'README.md'

git ls-files --others --exclude-standard
Staging untracked file: bin/git-check-status.sh
  - git add 'bin/git-check-status.sh'

git remote update
Fetching origin
Fetching upstream

git rev-parse --abbrev-ref HEAD
Fetching current branch with 'git fetch origin feature/debut-src'
  - git fetch origin feature/debut-src

git diff --cached --name-only
Committing staged modifications with 'git commit -m "Committing staged changes"'
  - git commit -m "Committing staged changes"

git rev-list HEAD...origin/feature/debut-src --count
Merging current branch with 'git merge origin/feature/debut-src'
  - git merge origin/feature/debut-src

Fetching branch 'develop' with 'git fetch origin develop'
  - git fetch origin develop

Fetching branch 'trunk' with 'git fetch origin trunk'
  - git fetch origin trunk

git fetch origin feature/debut-src; git commit -m "Committing staged changes"; git merge origin/feature/debut-src

git stash pop 'stash@{0}'; git add 'README.md'; git add 'bin/git-check-status.sh'; git fetch origin feature/debut-src; git commit -m "Committing staged changes"; git merge origin/feature/debut-src

```

## Subsequent run

```bash
$ git-check-status.sh 

git diff --name-only
Staging modified file: bin/git-check-status.sh
  - git add 'bin/git-check-status.sh'

git remote update
Fetching origin
Fetching upstream

git rev-parse --abbrev-ref HEAD
Fetching current branch with 'git fetch origin feature/debut-src'
  - git fetch origin feature/debut-src

git diff --cached --name-only
Committing staged modifications with 'git commit -m "Committing staged changes"'
  - git commit -m "Committing staged changes"

git rev-list HEAD...origin/feature/debut-src --count
Merging current branch with 'git merge origin/feature/debut-src'
  - git merge origin/feature/debut-src

Fetching branch 'develop' with 'git fetch origin develop'
  - git fetch origin develop

Fetching branch 'trunk' with 'git fetch origin trunk'
  - git fetch origin trunk

git add 'bin/git-check-status.sh'; git fetch origin feature/debut-src; git commit -m "Committing staged changes"; git merge origin/feature/debut-src

```