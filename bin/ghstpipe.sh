#!/bin/bash

HELP_set_env="Setup default environment"
set_env(){
    # Define prj variables

    #: "${PRJ_UPSTREAM:=ghstpipe0}"
    #: "${PRJ_UPSTREAM:=gh_test0}"
    : "${OPT_BASHDB:=""}"
    : "${OPT_WEB_URL:=""}"
    : "${OPT_VERBOSITY:="-v"}"
    VEBOSE='^-v$'
    VERY_VEBOSE='^-v+$'
    GHO='gho_' # don't track PAT in the line with gho_* (Personal Accesss Token)

    # Done#0: rename TRACK to TRACK, and WATCH to WATCH
    if [ -n "$OPT_BASHDB" ]; then # VSCode debug
        # Done#0: rename gh_hw_x to gh_hwx
        set -- PRJ_UPSTREAM=gh_hw_x init;
        cd .. # debugging ghstpipe in VSCode
        WATCH="" TRACK=""
        WAIT="" # turn off tracing to allow VSCode bash-debug. BUT break at each WAIT
    else
        WATCH="WATCH" TRACK="TRACK"
        WAIT="WAIT" # turn on wait
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

    if [ -z "$PRJ_UPSTREAM" ]; then
        read PRJ_UPSTREAM<<<$(git remote -v | ( read origin path method; expr "$path" : ".*/\(.*\)$_DOWNSTREAM"))
        : "${PRJ_UPSTREAM:=gh_hw0}"
    fi

    : "${USER_UPSTREAM:=$USER}"
    : "${USER_FEATURE:="$USER_UPSTREAM$_DOWNSTREAM"}"
    : "${PRJ_FEATURE:=$PRJ_UPSTREAM$_DOWNSTREAM}"
    : "${APP:=$PRJ_UPSTREAM-ts.sh}"
    : "${VER:=0.1.0}"
    : "${PAT=$HOME/.ssh/gh_pat_$USER_UPSTREAM.oauth}"

    # Done#0: rename feature/desc-a hotfix/desc-b
    : "${FEATURE:=feature/debut-src}"
    : "${TESTING:=}" # alt2
    : "${FULLTEST:=}" # alt3
    : "${DEVELOP:=develop}"
    : "${STAGING:=}" # alt5
    : "${PREPROD:=}" # alt6
    : "${TRUNK=trunk}"

    # cf. https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/what-happens-to-forks-when-a-repository-is-deleted-or-changes-visibility#changing-a-private-repository-to-a-public-repository
    : "${VISIBILITY=private}"
    : "${VISIBILITY=public}"

    PIPELINE_FEATURE="$TESTING $FULLTEST $DEVELOP" # from FEATURE
    PIPELINE_UPSTREAM="$STAGING $PREPROD $TRUNK" # from DEVELOP
    PIPELINE_TAIL="$FEATURE $PIPELINE_FEATURE $PIPELINE_UPSTREAM"
    REV_PIPELINE_HEAD="$PREPROD $STAGING $DEVELOP $FULLTEST $TESTING $FEATURE"

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

    eval `get_GH_PAT`
    # echo USER_UPSTREAM_TOKEN=$USER_UPSTREAM_TOKEN
    # echo USER_FEATURE_TOKEN=$USER_FEATURE_TOKEN

    if [ -z "$USER_UPSTREAM_TOKEN" -o -z "$USER_FEATURE_TOKEN" ]; then
      . $PAT
    fi

    skip=TrUe
    skip=
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
    ghstpipe.sh USER_UPSTREAM=You VER=0.1.1 update release
    ghstpipe.sh USER_UPSTREAM=You update
    ghstpipe.sh USER_UPSTREAM=You VER=0.1.2 release

## Usage for your repo
    env USER_UPSTREAM=YourGHLogin PRJ_UPSTREAM=YourGHProgram APP=YourAppName APP=YourAppName VER=0.1.2 ghstpipe.sh setup feature update release

## SYNOPSYS
You need two github accounts: '\$USER_UPSTREAM' and '\$USER_FEATURE'

'git' and the 'gh' CLI are installed on my linux laptop. I wanted a bash
script that uses gh to create a $VISIBILITY repo for \$USER_UPSTREAM on github
called \$PRJ_UPSTREAM

Note: The project variables are to be stored in bash variables as follows:

    USER_UPSTREAM=YourGHLogin
    USER_FEATURE="YourGHLogin$_DOWNSTREAM"

    PRJ_UPSTREAM=YourGHProgram
    PRJ_FEATURE=YourGHProgram$_DOWNSTREAM

    APP=YourAppName

You probably need to update the script variables to reflect your GH name, and repo name etc..

You also need to generate a Github a Personal Authentication Token for each GitHub account and store in ```PAT=$HOME/.ssh/gh_pat_$USER_UPSTREAM```.oauth
### Options - these need to be performed in the given order.

 * setup
   - create_local_releasing_repo
   - create_releasing_repo
   - create_downstream_repo

 * feature
   - create_feature
   - add_feature

 * update
   - update_feature
   - merge_feature

 * release
   - create_pull_request
   - merge_pull_request
   - tag_and_release

 * init
   - setup
   - feature
   - update
   - release

# A crude guide to the sequence GHSTPIPE performs tasks:
 * On '\$TRUNK' create a README.md file containing the Line “Under
Construction”, and merge this into \$DEVELOP, then \$STAGING, then \$TRUNK.
 * Use 'gh repo create' and 'git push' to register the project under
\$USER_UPSTREAM at github.
 * Create a local empty git repository called \$PRJ_UPSTREAM
 * Instead of creating a 'master' branch, create a '\$TRUNK'.
 * Also create a '\$FEATURE' branch from '\$TESTING'.
 * Also create a '\$TESTING' branch from '\$DEVELOP'.
 * Also create a '\$DEVELOP' branch from '\$STAGING'.
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
 * Switch to the local \$DEVELOP branch, and synchronise with \$USER_FEATURE's
version of \$DEVELOP.

## EXAMPLE

    ghstpipe.sh PRJ_UPSTREAM=gh_hello_world init
    cd gh_hello_world$_DOWNSTREAM
    ghstpipe.sh update
    ghstpipe.sh VER=0.1.1 update release
    ghstpipe.sh update
    ghstpipe.sh update
    ghstpipe.sh VER=0.1.2 update release
    ghstpipe.sh update
    ghstpipe.sh update
    ghstpipe.sh update
    ghstpipe.sh VER=0.1.3 release

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
    LN=`caller | sed "s/ .*//"`
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

INDENT="===="

WATCH(){ # trace only, don't track errno in $?
    LN=`caller | sed "s/ .*//"`
    cmd="$*"
    [[ "$OPT_VERBOSITY" =~ $VERBOSE && ! "$*" =~ $GHO ]] && echo_Q $INDENT:$LN: "$@" 1>&2
    "$@" # || RAISE
}

TRACK(){
    LN=`caller | sed "s/ .*//"`
    cmd="$*"
    case "$skip" in
        ("")
            [[ "$OPT_VERBOSITY" =~ $VERBOSE && ! "$*" =~ $GHO ]] && echo_Q $INDENT:$LN: "$@" 1>&2
            "$@" || RAISE
        ;;
        (*)
            [[ "$OPT_VERBOSITY" =~ $VERBOSE && ! "$*" =~ $GHO ]] && echo_Q $INDENT:$LN: "$@" 1>&2
        ;;
    esac
}

RAISE(){
    errno="$?"
    LN=`caller 1 | sed "s/ .*//"`
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
    sleep 12 # 6 seconds is too fast sometimes
}

CO(){
    if [[ "$OPT_VERBOSITY" =~ $VERBOSE ]]; then
        echo
        echo "# $@"
    fi
}

AUTH(){
    if [ "$THIS_AUTH" != "$1" ]; then
        echo $1 | $WATCH gh auth login --with-token
        THIS_AUTH="$1"
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
    gh repo create NevilleDNZ/gh_staging0 --private --source=. --remote=origin --push
    git push --all
    mv ../gh_staging0 ../gh_staging0-upstream
    mkdir -p ../gh_staging0-downstream
    echo  '{"permission":"read"}' | gh api ...
    curl -X PATCH -H 'Authorization: token gho_...' https://api.github.com/user/repository_invitations/246898334
: create_downstream_repo
    gh auth login --with-token
    gh repo fork NevilleDNZ/gh_staging0 --fork-name gh_staging0-downstream --clone
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
: update_feature
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
: create_pull_request
    gh repo set-default https://github.com/NevilleDNZ-downstream/gh_staging0-downstream
    gh pr create --base develop --head NevilleDNZ-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into NevilleDNZ/gh_staging0:develop.' --repo NevilleDNZ/gh_staging0
: merge_pull_request
    gh auth login --with-token
    gh pr list --repo NevilleDNZ/gh_staging0
    gh pr merge 1 --repo NevilleDNZ/gh_staging0 --merge
: tag_and_release
    gh pr create --base staging --head NevilleDNZ:develop --title 'feature/debut-src integration into staging' --body 'Integrating feature/debut-src changes into staging.' --repo NevilleDNZ/gh_staging0
    gh pr merge 2 --repo NevilleDNZ/gh_staging0 --merge
    gh pr create --base trunk --head NevilleDNZ:staging --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo NevilleDNZ/gh_staging0
    gh pr merge 3 --repo NevilleDNZ/gh_staging0 --merge
    gh release create 0.1.1 --repo NevilleDNZ/gh_staging0 --title 'Version 0.1.1' --notes 'Initial release version 0.1.1'
: update
: update_feature
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
: update_feature
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
: create_pull_request
    gh repo set-default https://github.com/NevilleDNZ-downstream/gh_staging0-downstream
    gh pr create --base develop --head NevilleDNZ-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into NevilleDNZ/gh_staging0:develop.' --repo NevilleDNZ/gh_staging0
: merge_pull_request
    gh auth login --with-token
    gh pr list --repo NevilleDNZ/gh_staging0
    gh pr merge 4 --repo NevilleDNZ/gh_staging0 --merge
: tag_and_release
    gh pr create --base staging --head NevilleDNZ:develop --title 'feature/debut-src integration into staging' --body 'Integrating feature/debut-src changes into staging.' --repo NevilleDNZ/gh_staging0
    gh pr merge 5 --repo NevilleDNZ/gh_staging0 --merge
    gh pr create --base trunk --head NevilleDNZ:staging --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo NevilleDNZ/gh_staging0
    gh pr merge 6 --repo NevilleDNZ/gh_staging0 --merge
    gh release create 0.1.2 --repo NevilleDNZ/gh_staging0 --title 'Version 0.1.2' --notes 'Initial release version 0.1.2'
: update
: update_feature
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
: update_feature
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
: update_feature
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
    gh repo create NevilleDNZ/gh_test0 --private --source=. --remote=origin --push
    git push --all
    mv ../gh_test0 ../gh_test0-upstream
    mkdir -p ../gh_test0-downstream
    echo  '{"permission":"read"}' # | gh api ...
    curl -X PATCH -H 'Authorization: token gho_...' https://api.github.com/user/repository_invitations/246898605
: create_downstream_repo
    gh auth login --with-token
    gh repo fork NevilleDNZ/gh_test0 --fork-name gh_test0-downstream --clone
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
: update_feature
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
: create_pull_request
    gh repo set-default https://github.com/NevilleDNZ-downstream/gh_test0-downstream
    gh pr create --base develop --head NevilleDNZ-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into NevilleDNZ/gh_test0:develop.' --repo NevilleDNZ/gh_test0
: merge_pull_request
    gh auth login --with-token
    gh pr list --repo NevilleDNZ/gh_test0
    gh pr merge 1 --repo NevilleDNZ/gh_test0 --merge
: tag_and_release
    gh pr create --base trunk --head NevilleDNZ:develop --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo NevilleDNZ/gh_test0
    gh pr merge 2 --repo NevilleDNZ/gh_test0 --merge
    gh release create 0.1.1 --repo NevilleDNZ/gh_test0 --title 'Version 0.1.1' --notes 'Initial release version 0.1.1'
: update
: update_feature
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
: update_feature
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
: create_pull_request
    gh repo set-default https://github.com/NevilleDNZ-downstream/gh_test0-downstream
    gh pr create --base develop --head NevilleDNZ-downstream:develop --title 'feature/debut-src integration into upstream develop' --body 'Integrating feature/debut-src changes into NevilleDNZ/gh_test0:develop.' --repo NevilleDNZ/gh_test0
: merge_pull_request
    gh auth login --with-token
    gh pr list --repo NevilleDNZ/gh_test0
    gh pr merge 3 --repo NevilleDNZ/gh_test0 --merge
: tag_and_release
    gh pr create --base trunk --head NevilleDNZ:develop --title 'feature/debut-src integration into trunk' --body 'Integrating feature/debut-src changes into trunk.' --repo NevilleDNZ/gh_test0
    gh pr merge 4 --repo NevilleDNZ/gh_test0 --merge
    gh release create 0.1.2 --repo NevilleDNZ/gh_test0 --title 'Version 0.1.2' --notes 'Initial release version 0.1.2'
: update
: update_feature
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
: update_feature
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
: update_feature
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

    $TRACK git init
    $TRACK git checkout -b $TRUNK
    $TRACK git add .
    #$TRACK git commit -m "Commit (master/main) $TRUNK branch"
    # $WATCH git checkout $TRUNK # ignore initial error, for now!
    # git add README.md; git commit -m "first commit"; git branch -M trunk; git remote add origin https://github.com/NevilleDNZ/gh_hw0.git; git push -u origin trunk

    CO Add README.md in $FEATURE
    echo "# $TITLE" > README.md
    echo "" >> README.md
    echo "Under Construction" >> README.md
    $TRACK git add README.md
    $TRACK git commit -m "Add README.md with under construction message"

    CO Create branches as specified
    HEAD=$TRUNK
    for BASE in $REV_PIPELINE_HEAD; do
         $TRACK git checkout -b $BASE $HEAD
         HEAD=$BASE
    done

    # git merge staging ...; => Already up to date.
#    # ToDo#0: use REV_PIPELINE below??
#    CO Merge $FEATURE into $TESTING, $DEVELOP, $STAGING, and $TRUNK
#    HEAD=$FEATURE
#    for BASE in $PIPELINE_TAIL; do
#         $WATCH git checkout $BASE
#         $TRACK git merge $HEAD # does a merge need a commit?
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

    CO Create repo on GitHub under $USER_UPSTREAM
    $TRACK gh repo create $USER_UPSTREAM/$PRJ_UPSTREAM --$VISIBILITY --source=. --remote=origin --push
    $TRACK git push --all

    # if [ $PRJ_UPSTREAM = $PRJ_FEATURE ]; then # nee_DOWNSTREAM to be moved aside for $_DOWNSTREAM
        $TRACK mv ../$PRJ_UPSTREAM ../$PRJ_UPSTREAM$_UPSTREAM
        $TRACK mkdir -p ../$PRJ_FEATURE
    # fi

    CO Grant $USER_FEATURE fork rights "(handled via GitHub settings, not scriptable via gh CLI)"

    CO $USER_FEATURE MUST accept via notifications.

    if [ -z "$OPT_WEB_URL" ]; then
        read COLL_ID<<<$(
        WATCH echo '{"permission":"read"}' |
            TRACK gh api -X PUT /repos/$USER_UPSTREAM/$PRJ_UPSTREAM/collaborators/$USER_FEATURE --jq '.id' --input -
        )
        ECHO COLL_ID=$COLL_ID

        WATCH curl -X PATCH -H "Authorization: token $USER_FEATURE_TOKEN" https://api.github.com/user/repository_invitations/$COLL_ID
    else
        ECHO This step must be done manually on GitHub if needed, esp if $PRJ_UPSTREAM is a $VISIBILITY project
        # ECHO VISIT: https://github.com/$USER_UPSTREAM/$PRJ_UPSTREAM/settings/access "[Settings => Collaborators]" then
        ECHO then LOGGED IN as $USER_FEATURE https://github.com/notifications, "[$USER_FEATURE => Mailbox => # => Accept invitation]"
        $WAIT
    fi
    RACECONDITIONWAIT # GH can take a little time to do the above...

    CD .. # because PWD got renamed with the `mv` above
}

HELP_create_downstream="Switch to $USER_FEATURE and fork the repo, rename and clone"
create_downstream_repo(){

    CO Switch to $USER_FEATURE and fork the repo
    AUTH $USER_FEATURE_TOKEN
    # CD $PRJ_UPSTREAM$_UPSTREAM

    CO Rename $USER_FEATURE forked repo
    if [ $PRJ_UPSTREAM != $PRJ_FEATURE ]; then
        if [ -n "$OPT_WEB_URL" ]; then
            CO Rename $USER_FEATURE forked repo "(this feature is not supported by gh yet)"
            CO This step must be done manually on GitHub if needed.
            ECHO VISIT https://github.com/$USER_UPSTREAM$_DOWNSTREAM/$PRJ_UPSTREAM/settings
            ECHO ACTION manually rename $PRJ_UPSTREAM to $PRJ_FEATURE
            $WAIT
        else
        #$TRACK gh repo fork $USER_UPSTREAM/$PRJ_UPSTREAM --clone=false --fork-name $PRJ_FEATURE
            $TRACK gh repo fork $USER_UPSTREAM/$PRJ_UPSTREAM --fork-name $PRJ_FEATURE --clone
        # $TRACK gh repo rename $USER_FEATURE/$PRJ_UPSTREAM $PRJ_FEATURE || RAISE
            RACECONDITIONWAIT # GH can take a little time to do the FORK...
            CD $PRJ_FEATURE
            $TRACK git config --local checkout.defaultRemote origin # because fork creates both upstream and origin
# origin	https://github.com/NevilleDNZ-downstream/gh_staging0-downstream.git (fetch)
# origin	https://github.com/NevilleDNZ-downstream/gh_staging0-downstream.git (push)
# upstream	https://github.com/NevilleDNZ/gh_staging0.git (fetch)
# upstream	https://github.com/NevilleDNZ/gh_staging0.git (push)

        fi
    else
        #$TRACK gh repo fork $USER_UPSTREAM/$PRJ_UPSTREAM --clone=false
        $TRACK gh repo fork $USER_UPSTREAM/$PRJ_UPSTREAM --clone
        RACECONDITIONWAIT # GH can take a little time to do the FORK...
    fi

    CO Clone $USER_FEATURE forked repo
    # CD ..
    # $TRACK git clone https://github.com/$USER_FEATURE/$PRJ_FEATURE $PRJ_FEATURE
    # or: $TRACK gh repo clone $USER_FEATURE/$PRJ_FEATURE $PRJ_FEATURE
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
#    CD -
}

HELP_add_feature="Add first script"
add_feature(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE
    $WATCH git checkout $FEATURE # ignore initial error, for now!
    $TRACK git pull # with default # origin $FEATURE # QQQ

    $WATCH mkdir -p bin
    $WATCH echo "echo 'hello, world! $VER'" > bin/$APP
    $TRACK chmod ug+x bin/$APP
    $TRACK git add bin/$APP
    #Done#0: remove VER from commit
    $TRACK git commit -m "Add a foundation shell script $VER"
    $TRACK git push # with default # origin $FEATURE

    # CO Add another line to the script
    # $WATCH echo "echo 'Goodbye Cruel World!'" >> bin/$APP
    # $TRACK git commit -am "Update $APP with goodbye message"
#    CD -
}

HELP_update_feature="Update timestamp script"
update_feature(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE
    $WATCH git checkout $FEATURE # ignore initial error, for now!
    $TRACK git pull # with default # origin $FEATURE # QQQ

    CO Add another line to the script
    $TRACK echo "echo 'Updated @ `date +"%Y%m%d%H%M%S"` - $VER'" > bin/$APP
    #Done#0: remove VER from commit
    $TRACK git commit -am "Update $APP with $FEATURE"
    $TRACK git push # with default # origin $FEATURE
#    CD -
}

HELP_merge_feature="Merge $FEATURE into $DEVELOP"
merge_feature(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE

    HEAD=$FEATURE
    for BASE in $PIPELINE_FEATURE; do
        CO Switch to $BASE and sync
        # $WATCH git checkout -b $BASE origin/$BASE
        $WATCH git checkout $BASE
        $TRACK git pull # with default # origin $BASE # get any updates

        CO Merge $HEAD into $BASE
        $TRACK git merge $HEAD # WARNING: merge conflicts appear here.
        $TRACK git push # with default # origin $BASE
        HEAD=$BASE
    done
#    CD -

}

HELP_create_pull_request="Create pull request on USER_FEATURE's repo (using USER_FEATURE's token)"
create_pull_request(){

    AUTH $USER_FEATURE_TOKEN
    CD $PRJ_FEATURE

    $TRACK gh repo set-default https://github.com/$USER_FEATURE/$PRJ_FEATURE
    RACECONDITIONWAIT # GH can take a little time to do the above...

    # chatgpt: $TRACK gh pr create --base $USER_UPSTREAM:$TRUNK --head $DEVELOP --title "Feature A integration" --body "Integrating feature A changes into $TRUNK."
    BRANCH=$DEVELOP
    read PR_URL<<<$($TRACK gh pr create --base $BRANCH --head $USER_FEATURE:$BRANCH --title "$FEATURE integration into upstream $BRANCH" --body "Integrating $FEATURE changes into $USER_UPSTREAM/$PRJ_UPSTREAM:$BRANCH." --repo $USER_UPSTREAM/$PRJ_UPSTREAM) || RAISE
    RACECONDITIONWAIT # GH can take a little time to do the above...
    PR_NUMBER=$(echo $PR_URL | grep -o '[^/]*$')
    ECHO PR_NUMBER=$PR_NUMBER
}

HELP_merge_pull_request="Merge pull request on USER_UPSTREAM's repo (using USER_FEATURE's token)"
merge_pull_request(){

    CO Switch back to $USER_UPSTREAM to merge the PR "(this step should ideally be done manually for review)"
    AUTH $USER_UPSTREAM_TOKEN
    CD $PRJ_FEATURE

    CO Assuming PR number is known or retrieved via script, it would be merged like so:
    # gh pr merge <PR_NUMBER> --merge

    CO List pull requests for $USER_UPSTREAM repo
    $TRACK gh pr list --repo $USER_UPSTREAM/$PRJ_UPSTREAM

    # identify the pull request number, merge it.
    $TRACK gh pr merge "$PR_NUMBER" --repo $USER_UPSTREAM/$PRJ_UPSTREAM --merge
#    CD -
}

HELP_tag_and_release="Tag and Release"
tag_and_release(){

    AUTH $USER_UPSTREAM_TOKEN
    CD $PRJ_FEATURE

    CO Merge $DEVELOP into $STAGING
    CO Merge $STAGING into $TRUNK
    CO Tag and Release
    HEAD=$DEVELOP # from
    for BASE in $PIPELINE_UPSTREAM; do
        read PR_URL <<<$($TRACK gh pr create --base $BASE --head $USER_UPSTREAM:$HEAD --title "$FEATURE integration into $BASE" --body "Integrating $FEATURE changes into $BASE." --repo $USER_UPSTREAM/$PRJ_UPSTREAM) || RAISE
        PR_NUMBER=$(echo $PR_URL | grep -o '[^/]*$')
        $TRACK gh pr merge "$PR_NUMBER" --repo $USER_UPSTREAM/$PRJ_UPSTREAM --merge
        HEAD=$BASE
    done

    # Done#0: change v to repo name
    # Done#0: Auto increament $VER
    CO Create a GitHub release for the tag
    # was: $TRACK gh release create v$VER --repo $USER_UPSTREAM/$PRJ_UPSTREAM --title "Version $VER" --notes "Initial release version $VER"
    # was: $TRACK gh release create $PRJ_UPSTREAM-$VER --repo $USER_UPSTREAM/$PRJ_UPSTREAM --title "Version $VER" --notes "Initial release version $VER"
    $TRACK gh release create "$VER" --repo $USER_UPSTREAM/$PRJ_UPSTREAM --title "Version $VER" --notes "Initial release version $VER"
#    CD -
 }

setup(){
    $TRACK create_local_releasing_repo
    $TRACK create_releasing_repo
    $TRACK create_downstream_repo
}

feature(){
    $TRACK create_feature
    $TRACK add_feature
}

update(){
    $TRACK update_feature
    $TRACK merge_feature
}

release(){
    $TRACK create_pull_request
    $TRACK merge_pull_request
    $TRACK tag_and_release
}

init(){
    $TRACK setup
    $TRACK feature
    $TRACK update
    $TRACK release
}

base_test(){
    $TRACK setup
    $TRACK feature
    CD $PRJ_FEATURE
    $TRACK update
    VER=0.1.1 release
    $TRACK update
    $TRACK update
    VER=0.1.2 release
    $TRACK update
    $TRACK update
    VER=0.1.3 update release
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

while [ $# -gt 0 ]; do
#    CO "Processing argument: $1"
    case "$1" in
        (*=*)eval "$1";;
        (*) break;
    esac
    shift  # Move to the next argument
done

set_env "$@"

while [ $# -gt 0 ]; do
#    CO "Processing argument: $1"
    case "$1" in
        (*=*)eval "$1";;
        (*) $TRACK "$1";;
    esac
    shift  # Move to the next argument
done

CD "$PRJ_FEATURE"
AUTH $USER_FEATURE_TOKEN
git checkout $FEATURE
