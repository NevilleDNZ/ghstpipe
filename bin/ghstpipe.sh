#!/bin/bash

HELP_set_env="Setup default environment"
set_env(){
    # Define prj variables

    #: "${PRJ_UPSTREAM:=ghstpipe0}"
    #: "${PRJ_UPSTREAM:=gh_test0}"
    #: "${__BASHDB:="--bashdb"}"

    : "${__WRAP_UPSTREAM:=""}" # Pull an existing upstream repo and wrap it in a pipeline locally, then push
    : "${__WRAP_LOCAL:=""}" # Take an existing local repo and wrap it in a pipeline, and push upstream
    
    : "${__BASHDB:=""}"
    : "${__WEB_URL:=""}"
    : "${__VERBOSITY:="-v"}" # or -vv
    : "${__DRYRUN:=""}" # ToDo: IF the command updates git, then ECHO only, OTHERWISE execute
    : "${__INTERACTIVE:=""}" # ToDo: ECHO commands to be executed, and prompt Skip/Next/Continue
    : "${__COMMIT_ALL_DOWNSTREAM:=""}" # Commit ALL to DS, even the PRs to US - preserves filemod times in DS

# ToDo: maybe rename proc `update` to `merge_develop`
# ToDo: maybe rename proc `release` to `merge_release`

    VEBOSE='^-v$'
    VERY_VEBOSE='^-v+$' # or -vv
    GHO='gho_' # don't track PAT in the line with gho_* (Personal Accesss Token)
    NL=$'; \n'

    if [ -n "$__BASHDB" ]; then # VSCode debug
        WATCH="" ASSERT=""
        WAIT="" # turn off tracing to allow VSCode bash-debug. BUT break at each WAIT
        ECHO="echo"
    else
        WATCH="WATCH" ASSERT="ASSERT"
        WAIT="WAIT" # turn on wait
        ECHO="ECHO"
    fi

    case "$PRJ_UPSTREAM" in
        (ghstpipe)
            : "${TITLE="GitHub Sync and Tag Pipeline"}"
        ;;
        (gh_hw*)
            : "${TITLE="$PRJ_UPSTREAM: A classic Hello World project!"}"
            : "${PRJ_FEATURE:=$PRJ_UPSTREAM}"
        ;;
        (*)
            : "${TITLE="GitHub $PRJ_UPSTREAM Project"}"
        ;;
        ("")echo "Huh '$PRJ_UPSTREAM'?"; exit 1;;
    esac

    case "$USER" in
      (nevilled): "${USER_UPSTREAM:=NevilleDNZ}";;
    esac

    # Default other variables
    : "${_UPSTREAM:="-upstream"}"
    : "${_DOWNSTREAM:="-downstream"}"

    if [ ! -n "$PRJ_UPSTREAM" ]; then
        read PRJ_UPSTREAM <<< $(git remote -v | ( read origin path method; expr "$path" : ".*/\(.*\)$_DOWNSTREAM"))
        : "${PRJ_UPSTREAM:=gh_hw0}"
    fi

    : "${USER_UPSTREAM:=$USER}"
    : "${USER_FEATURE:="$USER_UPSTREAM$_DOWNSTREAM"}"
    : "${PRJ_FEATURE:=$PRJ_UPSTREAM$_DOWNSTREAM}"
    : "${APP:=$PRJ_UPSTREAM-ts.sh}"
    : "${RELEASE:=+++}"
    : "${PAT=$HOME/.ssh/gh_pat_$USER_UPSTREAM.oauth}"

    #: "${RELEASE_PREFIX:=release/}" # needed to uncloak releases to git from github
    : "${RELEASE_PREFIX:=""}" # but it creates "ghpl_test7-release-0.1.0.tar.gz" :-/
    : "${FEATURE_PREFIX:=feature/}"
    if [ -z "$FEATURE" ]; then # allow for alternate branches, esp hotfix/*
        read CURRENT <<<$(git branch --show-current) 2> /dev/null
        rc="$?"
        case "$rc" in
            (0) if [[ "$CURRENT" =~ (hotfix/.+|feature/.+) ]]; then
                    : "${FEATURE:=${CURRENT}}"
                else
                    echo "$0: You are in the wrong branch $CURRENT, try one of feature/* or hotfix/* ..." 1>&2
                    git branch 
                    exit "$rc"
                fi
            ;;
            (*) :"${FEATURE:=${FEATURE_PREFIX}debut-src}";;
        esac
    fi
    : "${TESTING:=}" # alt2
    : "${FULLTEST:=}" # alt3
    : "${BETA:=develop}"
    : "${STAGING:=}" # alt5
    : "${PREPROD:=}" # alt6
    : "${TRUNK=trunk}"

    : "${COMMIT_MESSAGE:="$FEATURE commit"}"
    : "${MERGE_MESSAGE:="$FEATURE merge"}"  

    # cf. https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/what-happens-to-forks-when-a-repository-is-deleted-or-changes-visibility#changing-a-private-repository-to-a-public-repository
    : "${VISIBILITY:=private}"
    : "${VISIBILITY:=public}"

    PIPELINE_FEATURE="$TESTING $FULLTEST $BETA" # from FEATURE
    PIPELINE_UPSTREAM="$STAGING $PREPROD $TRUNK" # from BETA
    PIPELINE_TAIL="$FEATURE $PIPELINE_FEATURE $PIPELINE_UPSTREAM"
    REV_PIPELINE_HEAD="$PREPROD $STAGING $BETA $FULLTEST $TESTING $FEATURE"

    if [ -n "$__COMMIT_ALL_DOWNSTREAM" ]; then
        BETA=$TRUNK
        PIPELINE_FEATURE="$PIPELINE_TAIL" # from FEATURE
        PIPELINE_UPSTREAM="" # from BETA
    fi 

     : "${GIT_MERGE:=""}"
#    git merge $GIT_MERGE # used to merge two or more development histories together. Here are some common options:
#
#    --no-ff: Performs a three-way merge, creating a merge commit even if the merge could be resolved as a fast-forward. This is useful for preserving the history of a feature branch.
#    --ff: Allows the merge to be resolved as a fast-forward when possible. This is the default behavior but can be specified explicitly.
#    --ff-only: Refuses to merge unless the current HEAD is already up-to-date or the merge can be resolved as a fast-forward.
#    --squash: Combines all changes into a single commit on top of the base branch without creating a merge commit.
#    --abort: Can be used to stop the merge process and try to go back to the pre-merge state if there are merge conflicts.

     : "${DEVELOP_MERGE:=--merge}"
     : "${GH_PR_MERGE:=--merge}"
#    re: gh pr merge - This subcommand merges a pull request on GitHub.
#    --auto: Enable auto-merge for the pull request.
#    --admin: Use administrator privileges to merge a pull request that does not meet the base branch protection settings.
#    --squash: Squash the commits into one commit before merging.
#    --rebase: Rebase the commits on top of the base branch before merging.
#    --merge: Use the merge commit strategy to merge the commits.

    # Get/Set GitHub Personal Access Tokens for $USER_UPSTREAM and $USER_FEATURE

    get_GH_PAT(){
        gh auth status -t | awk '
        BEGIN{
            USER_UPSTREAM="'"$USER_UPSTREAM"'";
            USER_FEATURE="'"$USER_FEATURE"'";
        }
        {
            if($2=="Logged")Logged=$7;
            else {
                if($2=="Token:"){
                    if(USER_UPSTREAM==Logged)print "USER_UPSTREAM_TOKEN="$NF;
                    else if(USER_FEATURE==Logged)print "USER_FEATURE_TOKEN="$NF;
                }
            }
        }'
    }

    eval "$(get_GH_PAT)"
    # echo USER_UPSTREAM_TOKEN=$USER_UPSTREAM_TOKEN
    # echo USER_FEATURE_TOKEN=$USER_FEATURE_TOKEN

    if [ -z "$USER_UPSTREAM_TOKEN" -o -z "$USER_FEATURE_TOKEN" ]; then
      . $PAT
    fi

    skip=TrUe
    skip=
}

set_msg(){
    # Usage: VAR 'template'
    export $1="$2"
    SUBJECT="$(echo "$COMMIT_MESSAGE" | head -1)"
    BODY="$(echo "$COMMIT_MESSAGE" | tail -n +2)"
    case "$1" in
        (DEVELOP_PR_TITLE) eval export $1='"$FEATURE integration into upstream $BRANCH $NL $SUBJECT"';;
        (DEVELOP_PR_BODY) eval export $1='"Integrating $FEATURE changes into $USER_UPSTREAM/$PRJ_UPSTREAM:$BRANCH $NL $BODY."';;
        (DEVELOP_MERGE_SUBJECT) eval export $1='"$SUBJECT"';;
        (DEVELOP_MERGE_BODY) eval export $1='"$BODY"';;
        (RELEASE_PR_TITLE) eval export $1='"$FEATURE integration into $BASE $NL $SUBJECT"';;
        (RELEASE_PR_BODY) eval export $1='"Integrating $FEATURE changes into $BASE $NL $BODY"';;
        (RELEASE_MERGE_SUBJECT) eval export $1='"$SUBJECT"';;
        (RELEASE_MERGE_BODY) eval export $1='"$BODY"';;
        (RELEASE_TITLE) eval export $1='"Release $RELEASE $NL $FEATURE/$SUBJECT"';;
        (RELEASE_NOTES) eval export $1='"Release $RELEASE $NL $FEATURE/$BODY"';;
        (*)echo HUH | RAISE;;
    esac
}

HELP_help="Description, usage and example"
help(){
cat << end_cat
# GHSTPipeline - GitHub Sync and Tag Pipeline - a bash script

*Under Construction*

Basically, a list of all the routine git & gh CLI tasks that need to be performed which releasing a new version of your program.  All in one place.

## USAGE
    ghstpipe.sh help
    ghstpipe.sh USER_UPSTREAM=You PRJ_UPSTREAM=gh_hw init
    cd gh_hw$_DOWNSTREAM
    ghstpipe.sh USER_UPSTREAM=You RELEASE=0.1.1 update release
    ghstpipe.sh USER_UPSTREAM=You update
    ghstpipe.sh USER_UPSTREAM=You RELEASE=+++ release # 0.1.2

## Usage for your repo
    env USER_UPSTREAM=YourGHLogin PRJ_UPSTREAM=YourGHProgram APP=YourAppName APP=YourAppName RELEASE=0.1.2 ghstpipe.sh setup feature update release

## SYNOPSYS
You need two github accounts: '\$USER_UPSTREAM' and '\$USER_FEATURE'

'git' and the 'gh' CLI are installed on my linux laptop. I wanted a bash
script that uses gh to create a $VISIBILITY repo for \$USER_UPSTREAM on github
called \$PRJ_UPSTREAM

Note: The project variables are to be stored in bash variables as follows:

    USER_UPSTREAM=YourGHLogin
    USER_FEATURE=YourGHLogin$_DOWNSTREAM

    PRJ_UPSTREAM=YourGHProgram
    PRJ_FEATURE=YourGHProgram$_DOWNSTREAM

    APP=YourAppName

You probably need to update the script variables to reflect your GH name, and repo name etc..

You also need to generate a Github a Personal Authentication Token for each GitHub account and store in PAT=$HOME/.ssh/gh_pat_$USER_UPSTREAM.oauth

### Options - these need to be performed in the given order.

 * setup
   - create_local_releasing_repo
   - create_releasing_repo
   - create_downstream_repo

 * feature
   - create_feature
   - add_feature

 * update
   - commit_feature
   - merge_feature

 * release
   - create_fork_pull_request
   - merge_fork_pull_request
   - pr_merge_tag_and_release

 * init
   - setup
   - feature
   - update
   - release

# A crude guide to the sequence GHSTPIPE performs tasks:
 * On '\$TRUNK' create a README.md file containing the Line “Under
Construction”, and merge this into \$BETA, then \$STAGING, then \$TRUNK.
 * Use 'gh repo create' and 'git push' to register the project under
\$USER_UPSTREAM at github.
 * Create a local empty git repository called \$PRJ_UPSTREAM
 * Instead of creating a 'master' branch, create a '\$TRUNK'.
 * Also create a '\$FEATURE' branch from '\$TESTING'.
 * Also create a '\$TESTING' branch from '\$BETA'.
 * Also create a '\$BETA' branch from '\$STAGING'.
 * Also create a '\$STAGING' branch from '\$TRUNK'.
 * Grant \$USER_FEATURE rights enough to fork \$PRJ_UPSTREAM.
 * Then clone the repo to \$USER_FEATURE's account, as a forked repo called
\$PRJ_UPSTREAM, including all branches and tags.
 * Include the use of a use "saved token" for both \$USER_UPSTREAM and \$USER_FEATURE.
 * If possible, use 'gh repo rename' to rename \$USER_FEATURE’s repo \$PRJ_UPSTREAM
to \$PRJ_FEATURE.
 * Then, using gh CLI, clone \$PRJ_FEATURE onto my local workstation’s local
directory as a local repo.  Include all branches and tags.
 * On the local workstation, create a feature branch called \$FEATURE. Then
using bash, create a simple python “Hello World” script (called
bin/\$APP) in this branch.
 * Add and then 'commit' these changes to the local repo.
 * Add another line to \$APP that print "Goodbye cruel world!"
 * Add and then 'commit' these changes to the local repo.
 * Switch to the local \$BETA branch, and synchronise with \$USER_FEATURE's
version of \$BETA.

## EXAMPLE

    ghstpipe.sh PRJ_UPSTREAM=gh_hello_world init
    cd gh_hello_world$_DOWNSTREAM
    ghstpipe.sh update
    ghstpipe.sh RELEASE=0.1.1 update release
    ghstpipe.sh update
    ghstpipe.sh update
    ghstpipe.sh RELEASE=+++ update release
    ghstpipe.sh update
    ghstpipe.sh update
    ghstpipe.sh update
    ghstpipe.sh RELEASE=0.1.3 release

## TODO - Implement and Enforce:

  * Branch Protection Rules

## "Code's Choreography: A Poetic Journey Through ghstpipe.sh"

    In a world of code, where changes flow like streams,
    A script named gshtpipe.sh fulfills developers' dreams.
    With variables set, and branches in play,
    It orchestrates GitHub in a unique ballet.

    From feature/debut to trunk, it weaves its tale,
    Creating, merging, releasing without fail.
    A pipeline of code, from start to end,
    It’s a developer’s helper, an electronic friend.

    From upstream sources to forks anew,
    It navigates the GitHub seas, so vast and blue.
    With variables set, a project's course it charts,
    Guiding through GitHub's collaborative arts.

    For staging and trunk, it sets its sight,
    Merging and tagging, with power and might.
    A pipeline it forms, from feature to release,
    Ensuring that coding efforts never cease.

    Through gh api calls, tokens in hand,
    It invites collaborators to join the band.
    With USER_UPSTREAM and FEATURE branches in tow,
    It crafts a world where developers grow.

    So here's to ghstpipe.sh, a script so fine,
    Bridging the gap 'twixt your code and mine.
    In the dance of branches, a ballet so grand,
    It leads us through GitHub's ever-changing land.

    A tool not just of code, but of rhyme,
    A testament to collaboration, transcending time.
    So raise your glasses, to this script we cheer,
    For making our GitHub journeys crystal clear.

    - Nova/Anon

## OPTIONS

end_cat
set | grep "^HELP_" | sed "s/^HELP_/    /"
exit

}

echo_q(){
    printf "%s " "${@@Q}"; echo
}

special='$( )*?`<>\\|&;'
qq_special='$`'

echo_Q(){
    sep="";
    for arg in "$@"; do
        printf "$sep";
        sep=" "
        case "$arg" in
        (*["$special'"'"']*)
            case "$arg" in
            (*'"'*)
                case "$arg" in
                    (*"'"*)printf "%s" "${arg@Q}";;
                    (*)printf "'%s'" "$arg";;
                esac;;
            (*"'"*)
                case "$arg" in
                    (*"$qq_special"*) printf "%q" "$arg";;
                    (*) printf '"%s"' "$arg";;
                esac;;
            (*) printf "'%s'" "$arg";;
            esac;;
        (*) printf "%s" "$arg";;
        esac
        sep=" "
    done
    echo
}

CD(){ # avoid dancing about the 2 directories...
    LN="$(caller | sed "s/ .*//")"
    cmd="CD $*"
    if [ "/-/" = "/$@/" ]; then
        true
    elif [ "$THIS_DIR" != "$@" ]; then
        if [ -d "$@" ]; then
            echo_Q $LN: cd "$@" 1>&2
            cd "$@" || RAISE
        else
            echo_Q $LN: cd "../$@" 1>&2
            cd "../$@" || RAISE
        fi
        THIS_DIR="$@"
    fi
}

INDENT="++++"

WATCH(){ # trace only, dont track errno in $?
    LN="$(caller | sed "s/ .*//")"
    cmd="$*"
    [[ "$__VERBOSITY" =~ $VERBOSE && ! "$*" =~ $GHO ]] && echo_Q $INDENT:$LN: "$@" 1>&2
    "$@" # || RAISE
}

ASSERT(){
    LN="$(caller | sed "s/ .*//")"
    cmd="$*"
    case "$skip" in
        ("")
            [[ "$__VERBOSITY" =~ $VERBOSE && ! "$*" =~ $GHO ]] && echo_Q $INDENT:$LN: "$@" 1>&2
            "$@" || RAISE
        ;;
        (*)
            [[ "$__VERBOSITY" =~ $VERBOSE && ! "$*" =~ $GHO ]] && echo_Q $INDENT:$LN: "$@" 1>&2
        ;;
    esac
}

RAISE(){
    errno="$?"
    LN="$(caller 1 | sed "s/ .*//")"
    case "$#" in
        (0) echo_Q RAISED:$LN/$errno: "$cmd" 1>&2;;
        (*) echo_Q RAISED:$LN/$errno: "$@" 1>&2;;
    esac
    exit "$errno"
}

ECHO(){
    echo "$@"
}

WAIT(){
    read -p "Press [Enter] when YOU have completed this WEB_URL task:"
}

RACECONDITIONWAIT(){ # A total HACK ;-)
    # GH can take a little time to do the above...
    if [ -n "$1" ]; then
        sleep=$1
    else
        sleep=12 # 6 seconds is too fast sometimes
    fi
    for((i=sleep; sleep; sleep--)); do
        echo -n $sleep.; sleep 1
    done
    echo ..
}

CO(){
    if [[ "$__VERBOSITY" =~ $VERBOSE ]]; then
        echo
        echo "# $@"
    fi
}

AUTH(){
    cmd="$*"
    # ECHO AUTH "was:$THIS_AUTH" cmp "want:$1"
    if [ "$THIS_AUTH" != "$1" ]; then
        for try in 1 2 3 4 5 6; do
            #echo PW="$1"
            if $WATCH gh auth login --with-token <<< "$1"; then
                rc="$?"
                THIS_AUTH="$1"
                echo AUTH: SUCCESS
                RACECONDITIONWAIT 6 # GH can take a little time to do the above...
                return "$rc"
            else
                $ECHO gh auth login --with-token
                rc="$?"
            fi
            RACECONDITIONWAIT 6 # GH can take a little time to do the above...
        done
        set -x
        RAISE
        THIS_AUTH="$1"
    else
        return 0
    fi
}

sample_runs(){
    cat << eof
$ ghstpipe0.sh PRJ_UPSTREAM=gh_staging STAGING=staging TESTING=testing staging_test
: staging_test
: setup
: create_local_releasing_repo
    gh auth login --with-token
    mkdir -p gh_staging0
    git init
    git checkout -b trunk
    git add .
    git add README.md
    git commit -m 'Add README.md with under construction message'
    git checkout -b staging trunk
    git checkout -b develop staging
    git checkout -b testing develop
    git checkout -b feature/debut-src testing
: create_releasing_repo
    gh repo create ABCDev/gh_staging0 --private --source=. --remote=origin --push
    git push --all
    mv ../gh_staging0 ../gh_staging0-upstream
    mkdir -p ../gh_staging0-downstream
    echo  '{"permission":"read"}' | gh api ...
    curl -X PATCH -H 'Authorization: token gho_...' https://api.github.com/user/repository_invitations/246898334
: create_downstream_repo
    gh auth login --with-token
    gh repo fork ABCDev/gh_staging0 --fork-name gh_staging0-downstream --clone
    git config --local checkout.defaultRemote origin
: feature
: create_feature
: add_feature
    git checkout feature/debut-src
    git pull
    mkdir -p bin
    echo "echo 'hello, world! 0.1.0'"
    chmod ug+x bin/gh_staging0-ts.sh
    git add bin/gh_staging0-ts.sh
    git commit -m 'Add a foundation shell script 0.1.0'
    git push
: update
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227164654 - 0.1.0'"
    git commit -am 'Update gh_staging0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout testing
    git pull
    git merge feature/debut-src
    git push
    git checkout develop
    git pull
    git merge testing
    git push
: create_fork_pull_request
    gh repo set-default https://github.com/ABCDev-downstream/gh_staging0-downstream
    gh pr create --base develop --head ABCDev-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into ABCDev/gh_staging0:develop.' --repo ABCDev/gh_staging0
: merge_fork_pull_request
    gh auth login --with-token
    gh pr list --repo ABCDev/gh_staging0
    gh pr merge 1 --repo ABCDev/gh_staging0 --merge
: pr_merge_tag_and_release
    gh pr create --base staging --head ABCDev:develop --title 'feature/debut-src integration into staging' --body 'Integrating feature/debut-src changes into staging.' --repo ABCDev/gh_staging0
    gh pr merge 2 --repo ABCDev/gh_staging0 --merge
    gh pr create --base trunk --head ABCDev:staging --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo ABCDev/gh_staging0
    gh pr merge 3 --repo ABCDev/gh_staging0 --merge
    gh release create 0.1.1 --target trunk --repo ABCDev/gh_staging0 --title 'Release 0.1.1' --notes 'Release 0.1.1'
: update
: commit_feature
    gh auth login --with-token
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227164742 - 0.1.0'"
    git commit -am 'Update gh_staging0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout testing
    git pull
    git merge feature/debut-src
    git push
    git checkout develop
    git pull
    git merge testing
    git push
: update
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227164750 - 0.1.0'"
    git commit -am 'Update gh_staging0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout testing
    git pull
    git merge feature/debut-src
    git push
    git checkout develop
    git pull
    git merge testing
    git push
: create_fork_pull_request
    gh repo set-default https://github.com/ABCDev-downstream/gh_staging0-downstream
    gh pr create --base develop --head ABCDev-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into ABCDev/gh_staging0:develop.' --repo ABCDev/gh_staging0
: merge_fork_pull_request
    gh auth login --with-token
    gh pr list --repo ABCDev/gh_staging0
    gh pr merge 4 --repo ABCDev/gh_staging0 --merge
: pr_merge_tag_and_release
    gh pr create --base staging --head ABCDev:develop --title 'feature/debut-src integration into staging' --body 'Integrating feature/debut-src changes into staging.' --repo ABCDev/gh_staging0
    gh pr merge 5 --repo ABCDev/gh_staging0 --merge
    gh pr create --base trunk --head ABCDev:staging --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo ABCDev/gh_staging0
    gh pr merge 6 --repo ABCDev/gh_staging0 --merge
    gh release create 0.1.2 --target trunk --repo ABCDev/gh_staging0 --title 'Release 0.1.2' --notes 'Release 0.1.2'
: update
: commit_feature
    gh auth login --with-token
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227164837 - 0.1.0'"
    git commit -am 'Update gh_staging0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout testing
    git pull
    git merge feature/debut-src
    git push
    git checkout develop
    git pull
    git merge testing
    git push
: update
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227164845 - 0.1.0'"
    git commit -am 'Update gh_staging0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout testing
    git pull
    git merge feature/debut-src
    git push
    git checkout develop
    git pull
    git merge testing
    git push
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227164853 - 0.1.3'"
    git commit -am 'Update gh_staging0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout testing
    git pull
    git merge feature/debut-src
    git push
    git checkout develop
    git pull
    git merge testing
    git push
:
$ ~/bin/ghstpipe0.sh PRJ_UPSTREAM=gh_test0 ghstpipe_test
: ghstpipe_test
: base_test
: setup
: create_local_releasing_repo
    gh auth login --with-token
    mkdir -p gh_test0
    git init
    git checkout -b trunk
    git add .
    git add README.md
    git commit -m 'Add README.md with under construction message'
    git checkout -b develop trunk
    git checkout -b feature/debut-src develop
: create_releasing_repo
    gh repo create ABCDev/gh_test0 --private --source=. --remote=origin --push
    git push --all
    mv ../gh_test0 ../gh_test0-upstream
    mkdir -p ../gh_test0-downstream
    echo  '{"permission":"read"}' # | gh api ...
    curl -X PATCH -H 'Authorization: token gho_...' https://api.github.com/user/repository_invitations/246898605
: create_downstream_repo
    gh auth login --with-token
    gh repo fork ABCDev/gh_test0 --fork-name gh_test0-downstream --clone
    git config --local checkout.defaultRemote origin
: feature
: create_feature
: add_feature
    git checkout feature/debut-src
    git pull
    mkdir -p bin
    echo "echo 'hello, world! 0.1.0'"
    chmod ug+x bin/gh_test0-ts.sh
    git add bin/gh_test0-ts.sh
    git commit -m 'Add a foundation shell script 0.1.0'
    git push
: update
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227165105 - 0.1.0'"
    git commit -am 'Update gh_test0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout develop
    git pull
    git merge feature/debut-src
    git push
: create_fork_pull_request
    gh repo set-default https://github.com/ABCDev-downstream/gh_test0-downstream
    gh pr create --base develop --head ABCDev-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into ABCDev/gh_test0:develop.' --repo ABCDev/gh_test0
: merge_fork_pull_request
    gh auth login --with-token
    gh pr list --repo ABCDev/gh_test0
    gh pr merge 1 --repo ABCDev/gh_test0 --merge
: pr_merge_tag_and_release
    gh pr create --base trunk --head ABCDev:develop --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo ABCDev/gh_test0
    gh pr merge 2 --repo ABCDev/gh_test0 --merge
    gh release create 0.1.1 --target trunk --repo ABCDev/gh_test0 --title 'Release 0.1.1' --notes 'Release 0.1.1'
: update
: commit_feature
    gh auth login --with-token
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227165145 - 0.1.0'"
    git commit -am 'Update gh_test0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout develop
    git pull
    git merge feature/debut-src
    git push
: update
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227165150 - 0.1.0'"
    git commit -am 'Update gh_test0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout develop
    git pull
    git merge feature/debut-src
    git push
: create_fork_pull_request
    gh repo set-default https://github.com/ABCDev-downstream/gh_test0-downstream
    gh pr create --base develop --head ABCDev-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into ABCDev/gh_test0:develop.' --repo ABCDev/gh_test0
: merge_fork_pull_request
    gh auth login --with-token
    gh pr list --repo ABCDev/gh_test0
    gh pr merge 3 --repo ABCDev/gh_test0 --merge
: pr_merge_tag_and_release
    gh pr create --base trunk --head ABCDev:develop --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo ABCDev/gh_test0
    gh pr merge 4 --repo ABCDev/gh_test0 --merge
    gh release create 0.1.2 --target trunk --repo ABCDev/gh_test0 --title 'Release 0.1.2' --notes 'Release 0.1.2'
: update
: commit_feature
    gh auth login --with-token
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227165230 - 0.1.0'"
    git commit -am 'Update gh_test0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout develop
    git pull
    git merge feature/debut-src
    git push
: update
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227165235 - 0.1.0'"
    git commit -am 'Update gh_test0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout develop
    git pull
    git merge feature/debut-src
    git push
: commit_feature
    git checkout feature/debut-src
    git pull
    echo "echo 'Updated @ 20240227165240 - 0.1.3'"
    git commit -am 'Update gh_test0-ts.sh with feature/debut-src'
    git push
: merge_feature
    git checkout develop
    git pull
    git merge feature/debut-src
    git push
eof
}
CO Configure github for $USER_UPSTREAM
HELP_create_local_releasing_repo="Create local repository; Create and merge branches as specified"
create_local_releasing_repo(){

    ECHO $USER_UPSTREAM and $USER_FEATURE must already exist on github
    $WAIT

    AUTH $USER_UPSTREAM_TOKEN

    CO Create local repository
    $WATCH mkdir -p $PRJ_UPSTREAM
    CD $PRJ_UPSTREAM

    if [ -n "$__WRAP_UPSTREAM" ]; then
        $ASSERT gh repo clone $USER_UPSTREAM/$PRJ_UPSTREAM .
        $ASSERT git fetch --all --tags
    else
        $ASSERT git init
    fi
    $ASSERT git config --local init.defaultBranch $BETA
    $WATCH git checkout -b $TRUNK
    $ASSERT git add .
    #$ASSERT git commit -m "Commit (master/main) $TRUNK branch"
    # $WATCH git checkout $TRUNK # ignore initial error, for now!
    # git add README.md; git commit -m "first commit"; git branch -M trunk; git remote add origin https://github.com/ABCDev/gh_hw0.git; git push -u origin trunk

    CO Add README.md in $FEATURE
    echo "# $TITLE" > README.md
    echo "" >> README.md
    echo "Under Construction" >> README.md
    $ASSERT git add README.md
    $ASSERT git commit -m "Add README.md with under construction message"

    CO Create branches as specified
    HEAD=$TRUNK
    for BASE in $REV_PIPELINE_HEAD; do
         $ASSERT git checkout -b $BASE $HEAD
         HEAD=$BASE
    done

    # git merge staging ...; => Already up to date.
#    # ToDo#0: use REV_PIPELINE below??
#    CO Merge $FEATURE into $TESTING, $BETA, $STAGING, and $TRUNK
#    HEAD=$FEATURE
#    for BASE in $PIPELINE_TAIL; do
#         $WATCH git checkout $BASE
#         $ASSERT git merge $GIT_MERGE $HEAD # does a merge need a commit?
#         HEAD=$BASE
#    done
    CD -
}

HELP_branch_protection="branch_protect repo on GitHub under $USER_UPSTREAM"
branch_protection(){
# Using yaml:
# https://stackoverflow.com/questions/71120146/allowing-only-certain-branches-to-pr-merge-to-mainmaster-branch
# Also:
cat << end_cat
Two suggestions from chatgpt:

#!/bin/bash

# Variables
GITHUB_USER="your_username" # Or organization name
REPO_NAME="your_repo_name"
TOKEN=$(gh auth status -t | grep Token: | awk '{print $2}') # Fetches the GitHub token used by gh
API_URL="https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/branches/master/protection"

# JSON data for enabling branch protection on master
# Adjust the settings according to your nee_DOWNSTREAM
JSON_DATA='{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}'

# Set branch protection on master using GitHub API
curl -X PUT $API_URL \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$JSON_DATA"


enforcer.yaml file

name: 'Check Branch'

on:
  pull_request:

jobs:
  check_branch:
    runs-on: ubuntu-latest
    steps:
      - name: Check branch
        if: github.base_ref == 'main' && github.head_ref != 'dev'
        run: |
          echo "ERROR: You can only merge to main from dev."
          exit 1

ChatGPT: GitHub

    Branch Protection Rules:
        Go to your repository's settings.
        Click on "Branches" in the sidebar.
        Under "Branch protection rules", click "Add rule".
        Enter master in the "Branch name pattern".
        Enable "Require pull request reviews before merging". This prevents direct pushes and requires changes to go through a pull request.
        You can also enable "Require status checks to pass before merging" and select checks that ensure the branch to be merged is up-to-date with develop or has passed certain CI/CD pipelines that enforce your workflow.

    CODEOWNERS File (for more granular control):
        You can use a CODEOWNERS file to define individuals or teams responsible for specific branches. While this doesn't block merging directly, it can be used in conjunction with required reviews to ensure only certain people can approve merges into master.

end_cat

    HEAD=$FEATURE
    for BASE in $PIPELINE_TAIL; do
         $WATCH branch protect $BASE $HEAD
         HEAD=$BASE
    done
}

HELP_create_releasing_repo="Create repo on GitHub under USER_UPSTREAM"
create_releasing_repo(){
    AUTH $USER_UPSTREAM_TOKEN
    CD $PRJ_UPSTREAM

    if [ -z "$__WRAP_UPSTREAM" ]; then
        CO Create repo on GitHub under $USER_UPSTREAM
        RACECONDITIONWAIT 6 # GH can take a little time to do the above...
        $ASSERT gh repo create $USER_UPSTREAM/$PRJ_UPSTREAM --$VISIBILITY --source=. --remote=origin --push
        RACECONDITIONWAIT 6 # GH can take a little time to do the above...
    fi
    

    $ASSERT git push --all
    $ASSERT gh repo edit $USER_UPSTREAM/$PRJ_UPSTREAM --default-branch $TRUNK

    # if [ $PRJ_UPSTREAM = $PRJ_FEATURE ]; then # nee_DOWNSTREAM to be moved aside for $_DOWNSTREAM
        $ASSERT mv ../$PRJ_UPSTREAM ../$PRJ_UPSTREAM$_UPSTREAM
        $ASSERT mkdir -p ../$PRJ_FEATURE
    # fi

    CO Grant $USER_FEATURE fork rights "(handled via GitHub settings, not scriptable via gh CLI)"

    CO $USER_FEATURE MUST accept via notifications.

    if [ -n "$__WEB_URL" ]; then
        ECHO This step must be done manually on GitHub if needed, esp if $PRJ_UPSTREAM is a $VISIBILITY project
        # ECHO VISIT: https://github.com/$USER_UPSTREAM/$PRJ_UPSTREAM/settings/access "[Settings => Collaborators]" then
        ECHO then LOGGED IN as $USER_FEATURE https://github.com/notifications, "[$USER_FEATURE => Mailbox => # => Accept invitation]"
        $WAIT
    else
        #read COLL_ID <<< $(
        #WATCH echo '{"permission":"read"}' |
        #    ASSERT gh api -X PUT /repos/$USER_UPSTREAM/$PRJ_UPSTREAM/collaborators/$USER_FEATURE --jq '.id' --input -
        #)
        RACECONDITIONWAIT # GH can take a little time to do the above...
        cmd="gh api -X PUT /repos/$USER_UPSTREAM/$PRJ_UPSTREAM/collaborators/$USER_FEATURE --jq .id --input -"
        COLL_ID=$( ASSERT $cmd <<< '{"permission":"read"}')  || RAISE $cmd
        ECHO COLL_ID=$COLL_ID

        #WATCH curl -X PATCH -H "Authorization: token $USER_FEATURE_TOKEN" https://api.github.com/user/repository_invitations/$COLL_ID
    fi
    # RACECONDITIONWAIT # GH can take a little time to do the above...

    CD .. # because PWD got renamed with the `mv` above
}

HELP_create_downstream="Switch to $USER_FEATURE and fork the repo, rename and clone"
create_downstream_repo(){

    CO Switch to $USER_FEATURE and fork the repo
    AUTH $USER_FEATURE_TOKEN
    # CD $PRJ_UPSTREAM$_UPSTREAM

    RACECONDITIONWAIT # GH can take a little time to do the above...
    WATCH gh api -X PATCH /user/repository_invitations/$COLL_ID
    RACECONDITIONWAIT # GH can take a little time to do the above...

    CO Rename $USER_FEATURE forked repo
    if [ $PRJ_UPSTREAM != $PRJ_FEATURE ]; then
        if [ -n "$__WEB_URL" ]; then
            CO Rename $USER_FEATURE forked repo "(this feature is not supported by gh yet)"
            CO This step must be done manually on GitHub if needed.
            ECHO VISIT https://github.com/$USER_UPSTREAM$_DOWNSTREAM/$PRJ_UPSTREAM/settings
            ECHO ACTION manually rename $PRJ_UPSTREAM to $PRJ_FEATURE
            $WAIT
        else
        #$ASSERT gh repo fork $USER_UPSTREAM/$PRJ_UPSTREAM --clone=false --fork-name $PRJ_FEATURE
            $ASSERT gh repo fork $USER_UPSTREAM/$PRJ_UPSTREAM --fork-name $PRJ_FEATURE --clone
        # $ASSERT gh repo rename $USER_FEATURE/$PRJ_UPSTREAM $PRJ_FEATURE || RAISE
            RACECONDITIONWAIT # GH can take a little time to do the FORK...
            CD $PRJ_FEATURE
            $ASSERT git config --local checkout.defaultRemote origin # because fork creates both upstream and origin
# origin	https://github.com/ABCDev-downstream/gh_staging0-downstream.git (fetch)
# origin	https://github.com/ABCDev-downstream/gh_staging0-downstream.git (push)
# upstream	https://github.com/ABCDev/gh_staging0.git (fetch)
# upstream	https://github.com/ABCDev/gh_staging0.git (push)

        fi
    else
        $ASSERT gh repo fork $USER_UPSTREAM/$PRJ_UPSTREAM --clone
        RACECONDITIONWAIT # GH can take a little time to do the FORK...
    fi

    CO Clone $USER_FEATURE forked repo
    # CD ..
    # $ASSERT git clone https://github.com/$USER_FEATURE/$PRJ_FEATURE $PRJ_FEATURE
    # or: $ASSERT gh repo clone $USER_FEATURE/$PRJ_FEATURE $PRJ_FEATURE
    # CD $PRJ_FEATURE
#    CD -
}

HELP_create_feature="Create feature branch $FEATURE and add Python script"
create_feature(){
    return # already created above, unless maybe this is a new feature - QQQ
    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE

    CO Create feature branch $FEATURE and add Python script
    $WATCH git checkout -b $FEATURE
    $ASSERT gh api -X PATCH /repos/$USER_FEATURE/$PRJ_FEATURE -f default_branch=$FEATURE
    $ASSERT git config --local init.defaultBranch $FEATURE # avoid commits to TRUNK
#    CD -
}

HELP_add_feature="Add first script"
add_feature(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE
    $WATCH git checkout $FEATURE # ignore initial error, for now!
    $ASSERT git pull # with default # origin $FEATURE # QQQ

    $WATCH mkdir -p bin
    $WATCH echo "echo 'hello, world! $RELEASE'" > bin/$APP
    $ASSERT chmod ug+x bin/$APP
    $ASSERT git add bin/$APP
    $ASSERT git commit -m "Add a foundation shell script"
    $ASSERT git push # with default # origin $FEATURE

    # CO Add another line to the script
    # $WATCH echo "echo 'Goodbye Cruel World!'" >> bin/$APP
    # $ASSERT git commit -am "Update $APP with goodbye message"
#    CD -
}

HELP_update_ts_feature="Update timestamp script - needed to create non-empty tests"
update_ts_feature(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE
    $WATCH git checkout $FEATURE # ignore initial error, for now!
    $ASSERT git pull # with default # origin $FEATURE # QQQ

    CO Add another line to the script
    $ASSERT echo "echo 'Updated @ "$(date +"%Y%m%d%H%M%S")" - $RELEASE'" > bin/$APP
    $ASSERT git commit -am "Update $APP with $FEATURE timestamp"
    $ASSERT git push # with default # origin $FEATURE
#    CD -
}

HELP_update_feature="Update developer added feature"
commit_feature(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE
    $WATCH git checkout $FEATURE # ignore initial error, for now!
    $ASSERT git pull # with default # origin $FEATURE # QQQ

    CO Add another line to the script
    $ASSERT git commit -am "$FEATURE commit" # "$COMMIT_MESSAGE"
    $ASSERT git push # with default # origin $FEATURE
#    CD -
}

HELP_merge_feature="Merge $FEATURE into $BETA"
merge_feature(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE

    HEAD=$FEATURE
    for BASE in $PIPELINE_FEATURE; do
        CO Switch to $BASE and sync
        # $WATCH git checkout -b $BASE origin/$BASE
        $WATCH git checkout $BASE
        $ASSERT git pull # with default # origin $BASE # get any updates

        CO Merge $HEAD into $BASE
        #$ASSERT git merge $GIT_MERGE $HEAD # WARNING: merge conflicts appear here.
        #$ASSERT git merge $GIT_MERGE -m "$MERGE_MESSAGE"  $HEAD # WARNING: merge conflicts appear here.
        $ASSERT git merge $GIT_MERGE -m "$HEAD => $BASE merge"  $HEAD # WARNING: merge conflicts appear here.
        $ASSERT git push # with default # origin $BASE
        HEAD=$BASE
    done
#    CD -

}

HELP_create_fork_pull_request="Create pull request on USER_FEATURE's repo for fork (using USER_FEATURE's token)"
create_fork_pull_request(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE

    $ASSERT gh repo set-default https://github.com/$USER_FEATURE/$PRJ_FEATURE
    RACECONDITIONWAIT # GH can take a little time to do the above...

    # chatgpt: $ASSERT gh pr create --base $USER_UPSTREAM:$TRUNK --head $BETA --title "Feature A integration" --body "Integrating feature A changes into $TRUNK."

    BRANCH=$BETA
    set_msg DEVELOP_PR_TITLE '$FEATURE integration into upstream $BRANCH'
    set_msg DEVELOP_PR_BODY 'Integrating $FEATURE changes into $USER_UPSTREAM/$PRJ_UPSTREAM:$BRANCH.'

    read PR_URL <<< $($ASSERT gh pr create --base $BRANCH --head $USER_FEATURE:$BRANCH --title "$DEVELOP_PR_TITLE" --body "$DEVELOP_PR_BODY" --repo $USER_UPSTREAM/$PRJ_UPSTREAM) || RAISE
    RACECONDITIONWAIT # GH can take a little time to do the above...
    read PR_NUMBER <<< $(echo $PR_URL | grep -o '[^/]*$')
    ECHO PR_NUMBER=$PR_NUMBER
    ASSERT test "$PR_NUMBER" != ""
}

HELP_merge_fork_pull_request="Merge pull request on USER_UPSTREAM's repo from fork (using USER_FEATURE's token)"
merge_fork_pull_request(){

    CO Switch back to $USER_UPSTREAM to merge the PR "(this step should ideally be done manually for review)"
    AUTH $USER_UPSTREAM_TOKEN
    CD $PRJ_FEATURE

    CO Assuming PR number is known or retrieved via script, it would be merged like so:
    # gh pr merge <PR_NUMBER> $GH_PR_MERGE

    CO List pull requests for $USER_UPSTREAM repo
    $WATCH gh pr list --repo $USER_UPSTREAM/$PRJ_UPSTREAM

    # identify the pull request number, merge it.
    set_msg DEVELOP_MERGE_SUBJECT ''
    set_msg DEVELOP_MERGE_BODY ''
    RACECONDITIONWAIT # GH can take a little time to do the above...
    $ASSERT gh pr merge "$PR_NUMBER" --repo $USER_UPSTREAM/$PRJ_UPSTREAM $DEVELOP_MERGE --subject "$DEVELOP_MERGE_SUBJECT" --body "$DEVELOP_MERGE_SUBJECT"
    PR_NUMBER=qqq
#    CD -
}

HELP_upstream_pr_merge="Create upstream's PR and merge"
upstream_pr_merge(){

    AUTH $USER_UPSTREAM_TOKEN
    CD $PRJ_FEATURE

    CO Merge $BETA into $STAGING
    CO Merge $STAGING into $TRUNK
    HEAD=$BETA # from
    for BASE in $PIPELINE_UPSTREAM; do
        set_msg RELEASE_PR_TITLE '$FEATURE integration into $BASE'
        set_msg RELEASE_PR_BODY 'Integrating $FEATURE changes into $BASE.'

        read PR_URL <<< "$($ASSERT gh pr create --base $BASE --head $USER_UPSTREAM:$HEAD --title "$RELEASE_PR_TITLE" --body "$RELEASE_PR_BODY" --repo $USER_UPSTREAM/$PRJ_UPSTREAM)" || RAISE
        PR_NUMBER=$(echo $PR_URL | grep -o '[^/]*$')
        set_msg RELEASE_MERGE_SUBJECT ''
        set_msg RELEASE_MERGE_BODY ''
        $ASSERT gh pr merge "$PR_NUMBER" --repo $USER_UPSTREAM/$PRJ_UPSTREAM $GH_PR_MERGE --subject "$RELEASE_MERGE_SUBJECT" --body "$RELEASE_MERGE_SUBJECT"
        PR_NUMBER=QQQ
        HEAD=$BASE
    done
    # CD -
}

HELP_upstream_tag_and_release="Create upstream's Tag and Release"
upstream_tag_and_release(){

    CO Tag and Release

    case "$RELEASE" in
        (+|++|+++)
            major_minor_patch="${RELEASE}"
            # typeof_major_minor_patch="${#RELEASE}" ???
            let typeof_major_minor_patch="${#RELEASE}"-1
            #read RELEASE <<< "$(gh release list --repo ABCDev/ghstpipe --json tagName,isLatest --jq '.[] | select(.isLatest==true) | .tagName')"
            read RELEASE <<< "$(gh release list --repo $USER_UPSTREAM/$PRJ_UPSTREAM --json tagName,isLatest --jq '.[] | .tagName' |
                                egrep -v '[-][0-9][0-9][0-9][0-9]|[-.]beta$' | sort -V | tail -1 )"
# removed due to some kind of bash/vscode bug/clash???
#            if [[ "$RELEASE" =~ ^$RELEASE_PREFIX([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
#                let BASH_REMATCH[$typeof_major_minor_patch]++
#                RELEASE="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            IFS="[-.]" read -ra mmp <<< "$RELEASE"
            if [ -n "${mmp[$typeof_major_minor_patch]}" ]; then
                let mmp[$typeof_major_minor_patch]++
                RELEASE="$(IFS="."; echo "${mmp[*]}")"
            else
                RELEASE=0.1.0
            fi
        ;;
    esac

    AUTH $USER_UPSTREAM_TOKEN
    CD $PRJ_FEATURE

    echo RELEASE="$RELEASE"
    set_msg RELEASE_TITLE 'Release $RELEASE'
    set_msg RELEASE_NOTES 'Release $RELEASE'

    CO Create a GitHub release for the tag
    $ASSERT gh release create "$RELEASE_PREFIX$RELEASE-beta" --target "$BETA" --repo $USER_UPSTREAM/$PRJ_UPSTREAM --title "$RELEASE_TITLE $NL beta" --prerelease --notes "Beta: $RELEASE_NOTES"
    RACECONDITIONWAIT
    $ASSERT gh release create "$RELEASE_PREFIX$RELEASE"      --target "$TRUNK" --repo $USER_UPSTREAM/$PRJ_UPSTREAM --title "$RELEASE_TITLE" --notes "$RELEASE_NOTES"
    RACECONDITIONWAIT 6 # GH can take a little time to do the above...

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE
    RACECONDITIONWAIT 6 # GH can take a little time to do the above...
# on downstream
    $ASSERT gh release create "$RELEASE_PREFIX$RELEASE-beta" --target "$BETA" --repo $USER_FEATURE/$PRJ_FEATURE --title "$RELEASE_TITLE $NL beta" --prerelease --notes "$RELEASE_NOTES"
# on upstream

    if [ -n "$major_minor_patch" ]; then
        RELEASE="$major_minor_patch"
        unset "$major_minor_patch"
    fi
#    CD -
 }

HELP_pr_merge_tag_and_release="Create upstream's PR, merge, Tag and Release"
pr_merge_tag_and_release(){
    $WATCH upstream_pr_merge
    $WATCH upstream_tag_and_release
}

setup(){
    $ASSERT create_local_releasing_repo
    $ASSERT create_releasing_repo
    $ASSERT create_downstream_repo
}

feature(){
    $ASSERT create_feature
    $ASSERT add_feature
}

update_ts(){
    $ASSERT update_ts_feature
    $ASSERT merge_feature
}

update(){
    $ASSERT commit_feature
    $ASSERT merge_feature
}

release(){
    $ASSERT create_fork_pull_request
    $ASSERT merge_fork_pull_request
    $ASSERT pr_merge_tag_and_release
}

init(){
    $ASSERT setup
    $ASSERT feature
    $ASSERT update
    $ASSERT release
}

base_test(){
    $ASSERT setup
    $ASSERT feature
    CD $PRJ_FEATURE
    $ASSERT update_ts
    RELEASE=0.1.1 release
    $ASSERT update_ts
    $ASSERT update_ts
    RELEASE=+++ release
    $ASSERT update_ts
    $ASSERT update_ts
    RELEASE=0.1.3 update_ts release
}

public_test(){
    VISIBILITY=public
    base_test
}

staging_test(){
    TESTING=testing STAGING=staging
    base_test
}


if [ "$#" = 0 ]; then
   set -- update
fi

if [ "$*" = "" ]; then
    # set -- PRJ_UPSTREAM=gh_hw_x init;
    set -- PRJ_UPSTREAM=ghpl_test"$(date +"%H%M%S")" base_test
    # set -- PRJ_UPSTREAM=ghpl_staging"$(date +"%H%M%S")" TESTING=testing STAGING=staging base_test
    cd .. # debugging ghstpipe in VSCode
fi


while [ $# -gt 0 ]; do
#    CO "Processing argument: $1"
    case "$1" in
        (*=*)eval "$1";;
        (*) break;
    esac
    shift  # Move to the next argument
done

case "$1" in
    (staging_test)STAGING=staging; TESTING=testing;;
    (*)true;;
esac

set_env "$@"

while [ $# -gt 0 ]; do
#    CO "Processing argument: $1"
    case "$1" in
        (*=*)eval "$1";;
        (*) $ASSERT "$1";;
    esac
    shift  # Move to the next argument
done

CD "$PRJ_FEATURE"
AUTH $USER_FEATURE_TOKEN
git checkout $FEATURE
