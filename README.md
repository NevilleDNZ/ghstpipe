# GHSTPipe - GitHub Sync and Tag Pipeline - a bash script

*Under Construction*

Basically, a list of all the routine git & gh CLI tasks that need to be performed which releasing a new version of your program.  All in one place.

## USAGE
    ghstpipe.sh help
    ghstpipe.sh USER_UPSTREAM=You PRJ_UPSTREAM=gh_hw init
    cd gh_hw-downstream
    ghstpipe.sh USER_UPSTREAM=You VER=0.1.1 update release
    ghstpipe.sh USER_UPSTREAM=You update
    ghstpipe.sh USER_UPSTREAM=You VER=0.1.2 release

## Usage for your repo
    env USER_UPSTREAM=YourGHLogin PRJ_UPSTREAM=YourGHProgram APP=YourAppName APP=YourAppName VER=0.1.2 ghstpipe.sh setup feature update release

## SYNOPSYS
You need two github accounts: '$USER_UPSTREAM' and '$USER_FEATURE'

'git' and the 'gh' CLI are installed on my linux laptop. I wanted a bash
script that uses gh to create a private repo for $USER_UPSTREAM on github
called $PRJ_UPSTREAM

Note: The project variables are to be stored in bash variables as follows:

    USER_UPSTREAM=YourGHLogin
    USER_FEATURE="YourGHLogin-downstream"

    PRJ_UPSTREAM=YourGHProgram
    PRJ_FEATURE=YourGHProgram-downstream

    APP=YourAppName

You probably need to update the script variables to reflect your GH name, and repo name etc..

You also need to generate a Github a Personal Authentication Token for each GitHub account and store in .oauth
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
 * On '$TRUNK' create a README.md file containing the Line “Under
Construction”, and merge this into $DEVELOP, then $STAGING, then $TRUNK.
 * Use 'gh repo create' and 'git push' to register the project under
$USER_UPSTREAM at github.
 * Create a local empty git repository called $PRJ_UPSTREAM
 * Instead of creating a 'master' branch, create a '$TRUNK'.
 * Also create a '$FEATURE' branch from '$TESTING'.
 * Also create a '$TESTING' branch from '$DEVELOP'.
 * Also create a '$DEVELOP' branch from '$STAGING'.
 * Also create a '$STAGING' branch from '$TRUNK'.
 * Grant $USER_FEATURE rights enough to fork $PRJ_UPSTREAM.
 * Then clone the repo to $USER_FEATURE's account, as a forked repo called
$PRJ_UPSTREAM, including all branches and tags.
 * Include the use of a use "saved token" for both $USER_UPSTREAM and $USER_FEATURE.
 * If possible, use 'gh repo rename' to rename $USER_FEATURE’s repo $PRJ_UPSTREAM
to $PRJ_FEATURE.
 * Then, using gh CLI, clone $PRJ_FEATURE onto my local workstation’s local
directory as a local repo.  Include all branches and tags.
 * On the local workstation, create a feature branch called $FEATURE. Then
using bash, create a simple python “Hello World” script (called
bin/$APP) in this branch.
 * Add and then 'commit' these changes to the local repo.
 * Add another line to $APP that print "Goodbye cruel world!"
 * Add and then 'commit' these changes to the local repo.
 * Switch to the local $DEVELOP branch, and synchronise with $USER_FEATURE's
version of $DEVELOP.

## EXAMPLE

    ghstpipe.sh PRJ_UPSTREAM=gh_hello_world init
    cd gh_hello_world-downstream
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

    add_feature='Add first script'
    branch_protection='branch_protect repo on GitHub under '
    create_downstream='Switch to  and fork the repo, rename and clone'
    create_feature='Create feature branch  and add Python script'
    create_local_releasing_repo='Create local repository; Create and merge branches as specified'
    create_pull_request='Create pull request on USER_FEATURE'\''s repo (using USER_FEATURE'\''s token)'
    create_releasing_repo='Create repo on GitHub under USER_UPSTREAM'
    help='Description, usage and example'
    merge_feature='Merge  into '
    merge_pull_request='Merge pull request on USER_UPSTREAM'\''s repo (using USER_FEATURE'\''s token)'
    set_env='Setup default environment'
    tag_and_release='Tag and Release'
    update_feature='Update timestamp script'
