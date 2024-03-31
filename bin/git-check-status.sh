#!/bin/bash

help(){
     man <(cat << eof
O.TH GIT-UPDATE-SUGGESTER 1 "30 March 2024" "version 1.0" "User Commands"
.SH NAME
git-update-suggester \- suggests git and GitHub actions based on the current repository state.

.SH SYNOPSIS
.B git-update-suggester
.RI [ options ]

.SH DESCRIPTION
.B git-update-suggester
is a Bourne shell script that analyzes the current state of a git repository to suggest a series of git and GitHub (gh) commands. These suggestions aim to update the repository based on its current state, including stashing, staging modifications, committing, fetching, merging, and releasing.

The script performs a series of checks to determine necessary actions, such as unstashing changes, staging and committing modifications, fetching and merging updates from the remote repository, and suggesting the next release number based on semantic versioning.

.SH OPTIONS
This script does not take any options. It operates solely based on the state of the current git repository.

.SH STEPS
The script checks and suggests actions for the following steps, if necessary:

.TP
.B A)
Individually unstash each stash.
.TP
.B B)
Individually stage each current modification.
.TP
.B C)
Fetch the current branch, only if necessary.
.TP
.B D)
Individually commit all currently staged files/modifications.
.TP
.B E)
Merge the current branch, only if necessary.
.TP
.B F)
Fetch the branch, only if determined to be absolutely necessary.
.TP
.B G)
Merge the branch, only if determined to be absolutely necessary.
.TP
.B H)
Create a GitHub release with the next release number based on semantic versioning.

.SH EXAMPLES
Running the script in a git repository directory will produce output similar to the following, depending on the repository state:

.nf
$ ./git-update-suggester
Unstashing 2 stashes with 'git stash pop'
Staging modifications with 'git add .'
Fetching current branch with 'git fetch origin master'
Committing staged modifications with 'git commit -m "Committing staged changes"'
Merging current branch with 'git merge origin/master'
Creating a release with 'gh release create v1.0.1'
.fi

.SH AUTHOR
Written by ChatGPT/NevilleDNZ

.SH "SEE ALSO"
.BR git (1),
.BR gh (1),
.BR sh (1)

.SH BUGS
Report bugs to NevilleD.git-check-status@sgr-a.net
eof
)
# ChatGPT input:
#
# Write a strict POSIX/BSD Bourne shell script (for backward compatability
# with BSD) to suggest updates on the current repo state of pending git
# (and gh) commands.
# Avoid using `cut`.
# For each step A) to H) have the script produce ( via echo 1>&2 ) a
# commentary (inserting the actual cmd in the comment) only if the action
# is required.
# Build a string as ";" separated list of the commands required to complete
# the update.
# 
# A) to individually unstash each stash.
# B) to individually stage each current modifications
# C) to fetch current branch, only if necessary.
# D) to individually commit all currently staged files/modifications.
# E) to merge current branch, only if necessary.
# 
# Determine the next release number.
# 
# (Bearing in mind a release number is of the format
# Major#.minor#.patch#[-beta] ).  Hint: use `sort -V`
# eg.  0.1.2 0.1.3 0.1.5-alpha 0.1.6-beta 0.1.7-beta
# select release Major number that starts with a number.
# 
# Then for all local branches that are out of date:
# (hint create -and use - a function called check_branch_up_to_date that
# return mo as a string):
# F) `fetch` the branch, detect, then do, only if necessary. nb. only
#     fetch only if determined to be absolutely necessary.
# G) `merge` the branch, detect, then do, only if necessary. nb. only
#     merge only if determined to be absolutely necessary.
# H) do a `gh release` was per the next release number.
# 
# 
# Finally print a "; " separated list of the commands required to do
# the above.
# Don't forget to double-quote shell variables, do avoid empty string
# shell syntax errors.
# 
    exit
}

case "$1" in 
    (-h|--help)help;;
    (*);;
esac

# Initialize command list
CMD_LIST=""

indent="  - "
COMMENT(){
    echo
    for l in "$@"; do
        echo "$l"
    done
}

# Function to add commands to the list
add_cmd() {
    echo "$indent$1"
    if [ -z "$CMD_LIST" ]; then
        CMD_LIST="$1"
    else
        CMD_LIST="$CMD_LIST; $1"
    fi
}

# A) Unstash each stash
query="git stash list"
#stash_count=$($query | wc -l)
#if [ "$stash_count" -gt 0 ]; then
#    COMMENT "$query" "Unstashing $stash_count stashes with 'git stash pop'"
#    for i in $(seq 1 "$stash_count"); do
#        add_cmd "git stash pop"
#    done
#fi
# List all stashes and reverse the list to pop from the oldest to the newest
while IFS= read -r line; do
    # Extract the stash ID from the line
    stash_id=$(echo "$line" | sed -n 's/^\(stash@{[0-9]*}\).*/\1/p')
    if [ -n "$stash_id" ]; then
        COMMENT "$query" "Popping stash: $stash_id"
        add_cmd "git stash pop '$stash_id'"
    fi
done <<<$(git stash list | sed -n '1!G;h;$p' )
# B) Stage current modifications
#query="git status --porcelain"
#if [ -n "$($query)" ]; then
#    COMMENT "$query" "Staging modifications with 'git add .'"
#    add_cmd "git add ."
#fi

# First, get all modified files
query="git diff --name-only"
while IFS= read -r file; do
    if [ -n "$file" ]; then
        COMMENT "$query" "Staging modified file: $file"
        add_cmd "git add '$file'"
    fi
done <<<$($query)

# Next, get all untracked files
query="git ls-files --others --exclude-standard"
while IFS= read -r file; do
    if [ -n "$file" ]; then
        COMMENT "$query"  "Staging untracked file: $file"
        add_cmd "git add '$file'"
    fi
done <<<$($query)

# C) Fetch current branch if necessary
COMMENT "git remote update"
git remote update
query="git rev-parse --abbrev-ref HEAD"
current_branch=$($query)
if [ "$(git rev-list HEAD...origin/"$current_branch" --count)" -gt 0 ]; then
    COMMENT "$query" "Fetching current branch with 'git fetch origin $current_branch'"
    add_cmd "git fetch origin $current_branch"
fi

# D) Commit staged files
query="git diff --cached --name-only"
if [ -n "$($query)" ]; then
    COMMENT "$query" "Committing staged modifications with 'git commit -m \"Committing staged changes\"'"
    add_cmd "git commit -m \"Committing staged changes\""
fi

query="git rev-list HEAD...origin/"$current_branch" --count"
# E) Merge current branch if necessary
if [ "$($query)" -gt 0 ]; then
    COMMENT "$query" "Merging current branch with 'git merge origin/$current_branch'"
    add_cmd "git merge origin/$current_branch"
fi

## Determine the next release number
#next_release=$(git tag | grep '^[0-9]' | sort -V | tail -n 1 | awk -F. -v OFS=. '{$NF++;print}')
#echo 1>&2 "Next release number should be $next_release."
#
#check_branch_up_to_date() {
#    branch_name="$1"
#    git fetch origin "$branch_name" > /dev/null 2>&1
#    query="git rev-list HEAD...origin/"$branch_name" --count"
#    case "$($query)" in
#        ([1-9]*) echo "no";;
#        (0) echo "yes";;
#        (*) echo "None";;
#    esac
#}
#
## F) Fetch branch if necessary
## G) Merge branch if necessary
## This part assumes you manage branches appropriately and uses a simplified check
#query="git branch -r "
#for branch in $($query| awk '{print $1}'); do
#    if [ "$(check_branch_up_to_date "$branch")" = "no" ]; then
#        COMMENT "$query" "Fetching and potentially merging out-of-date branch '$branch'"
#        add_cmd "git fetch origin $branch"
#        add_cmd "git merge origin/$branch"
#    fi
#done

# Function to check if fetching is necessary
check_if_fetching_is_necessary() {
    branch_name="$1"
    # Check for remote updates available for the branch without actually fetching them
    fquery="git ls-remote origin "$branch_name" | cut -f 1"
    remote_commits=$($fquery)
    local_commits=$(git rev-parse "$branch_name")

    if [ "$remote_commits" != "$local_commits" ]; then
        echo "needs_fetch"
    else
        echo "up_to_date"
    fi
}

# Function to check if merging is necessary
check_if_merging_is_necessary() {
    branch_name="$1"
    # Ensure we have the latest info for comparison
    git fetch origin "$branch_name" > /dev/null 2>&1

    local_branch=$(git rev-parse "$branch_name")
    remote_branch=$(git rev-parse "origin/$branch_name")
    mquery="git merge-base "$branch_name" "origin/$branch_name""
    base_point=$($mquery)

    if [ "$local_branch" = "$remote_branch" ]; then
        echo "up_to_date"
    elif [ "$local_branch" = "$base_point" ]; then
        echo "needs_merge"
    else
        echo "diverged"
    fi
}

# Implement fetching and merging only when necessary
git branch --list | sed 's/* //' | while read -r branch; do
    # Skip if it's the current branch, as we've already handled it
    if [ "$branch" = "$current_branch" ]; then
        continue
    fi

    query=""
    fetch_status=$(check_if_fetching_is_necessary "$branch")
    if [ "$fetch_status" = "needs_fetch" ]; then
        COMMENT $fquery "Fetching branch '$branch' with 'git fetch origin $branch'" 1>&2
        add_cmd "git fetch origin $branch"
    fi

    query=""
    merge_status=$(check_if_merging_is_necessary "$branch")
    if [ "$merge_status" = "needs_merge" ]; then
        COMMENT $mquery "Merging branch '$branch' with 'git merge origin/$branch'" 1>&2
        add_cmd "git merge origin/$branch"
    elif [ "$merge_status" = "diverged" ]; then
        COMMENT $mquery "Branch '$branch' has diverged. Manual merge required." 1>&2
    fi
done

# H) gh release for the next release number
query="git log "$last_release"..HEAD --oneline"
unreleased_commits="$($query)"
if [ -z "$unreleased_commits" ]; then
    :
else
    echo "Creating a release with 'gh release create $next_release'"
    add_cmd "gh release create $next_release"
fi
echo

# Print the command list
echo "$CMD_LIST"

