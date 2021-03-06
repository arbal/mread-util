# This script should be sourced from your bash_profile!
# Required shell variables (you should set these here or in your bash profile):
# - GITHUB_USERNAME
# Edit this variable if you cloned this somewhere other than ~/Developer:

export MREAD_UTIL_BASE_PATH="$HOME/Developer/mread-util"

###

utiledit() {
    $EDITOR $MREAD_UTIL_BASE_PATH/mread-util.sh
    source $MREAD_UTIL_BASE_PATH/mread-util.sh
}

bashedit() {
    $EDITOR ~/.bash_profile
    source ~/.bash_profile
}

### GREP ###

gripeb() {
    echo grep --color=auto -rIE --exclude-dir=\.git "$@" . >&2
    grep --color=auto -rIE --exclude-dir=\.git "$@" . | less -r
}

alias grip='grep -i'
alias gripe='gripeb 2>/dev/null'
alias igripe='gripe -i'
alias jgripe='gripe --include \*.java'
alias jigripe='jgripe -i'
alias jsgripe='gripe --include \*.js --include \*.mustache --exclude moment.js --exclude bundle.js --exclude \*.\*.js --exclude \*-min.js --exclude main.js --exclude templates.js --exclude-dir node_modules --exclude-dir testingData --exclude-dir packages --exclude-dir __tests__'
alias jsigripe='jsgripe -i'
alias sqlgripe='gripe --include \*.sql --exclude-dir target'
alias sqligripe='sqlgripe -i'

### GIT ###

alias g='git'

alias clone='g clone'

alias status='g status'

alias fetch='g fetch'

alias adda='g add -A'
alias addu='g add -u'

alias push='g push'
alias pushf='g push --force-with-lease'
alias pushu='g push -u'

alias blist='g branch -l --list'

alias hdiff='g diff HEAD'
alias fulldiff='g diff-index --binary'

alias changedfiles='g diff --name-only HEAD~1'

co() {
    fetch
    g checkout "$@"
}

alias master='co master && fetch && g reset --hard origin/master'
alias revert='co HEAD~1'

alias cherry='g cherry-pick'

alias commit='g commit -m'
alias admit='addu && commit'

alias resetmaster='fetch && g reset --hard origin/master'

latest() {
    fetch && g reset --hard origin/$(g rev-parse --abbrev-ref HEAD)
}

newb() {
    co -b "$@" && pushu
}

rebase() {
    fetch && g rebase "$@" origin/master
}

amend() {
    if [ "$1" == "" ]; then
        g commit --amend --no-edit
    else
        commit "$@" --amend
    fi
}

alias commend='addu && amend'

alias crunch='addu && amend && fetch && rebase && pushf'

hascommit() {
    g log $1 | grep $2
}

# remove all local branches except for the current one + master
gpurge() {
    blist | grep -v '^\*' | grep -oE '[^ ]+' | grep -vE '^master$' | while read line; do g branch -D $line; done
    g prune
}

pruneall() {
    g reflog expire --expire=now --all
    g gc --aggressive --prune=now
}

branchpoint() {
    g log -g --pretty=oneline $(g rev-parse --abbrev-ref HEAD) | tail -n 1 | awk '{ print "'$'"1; }'
}

delcommit() {
    local BRANCH_POINT=$(branchpoint)
    local HEAD=$(g rev-parse HEAD)

    g reset --hard $BRANCH_POINT

    g rev-list $BRANCH_POINT...$HEAD | tac | while read line; do
        if [ "$line" != "$1" ]; then
            cherry $line
        fi
    done
}

alias branchdiff='g diff $(branchpoint)...HEAD'

alias rbcont='addu && g rebase --continue'

remotebranch() {
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null | grep -oE '[^/]+$'
}

localbranch() {
    g branch 2> /dev/null | grep -E '^\*' | awk '{ print $2; }'
}

### GITHUB ###

github_create_repo() {
    local ARG1=''
    if [ "$2" == "" ]; then
        echo "Usage: github_create_repo [username] [reponame] <oneTimeCode>"
        return 1
    fi
    if [ "$3" != "" ]; then
        ARG1="X-GitHub-OTP: $3"
    fi
    local ARG2="{\"name\":\"$2\"}"

    http_code=$(curl -u $1 -H "$ARG1" -d $ARG2 https://api.github.com/user/repos -s -o /dev/null -w "%{http_code}")
    if [ $http_code -ge 300 ] || [ $http_code -lt 200 ]; then
        echo "Error code: $http_code"
        return $http_code
    fi
    return 0
}

ghcr() {
    local reponame=$(basename "$PWD")
    github_create_repo $GITHUB_USERNAME $reponame $@
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        return $exit_code
    fi
    echo "# $reponame" > README.md
    g init
    g add README.md
    commit 'init repo with README'
    g remote add origin git@github.com:$GITHUB_USERNAME/$reponame.git
    g push -u origin master
}

rewrite-all-committers() {
    local committer_name=$(git config user.name)
    local committer_mail=$(git config user.email)

    git filter-branch --env-filter "
        export GIT_COMMITTER_NAME=\"$committer_name\"
	export GIT_COMMITTER_EMAIL=\"$committer_mail\"
	export GIT_AUTHOR_NAME=\"$committer_name\"
	export GIT_AUTHOR_EMAIL=\"$committer_mail\"
    " --tag-name-filter cat -- --branches --tags
}

cloneme() {
    clone git@github.com:$GITHUB_USERNAME/$1
}

### DOS COMPAT ###

alias cls='clear'
alias where='which'
alias tracert='traceroute'

### SHELL/UTIL HELPERS ###

if [ -z $(which tac) ]; then
    alias tac='tail -r'
fi

# a better version of 'history'
h() {
    if [ "$1" == "" ]; then
        history | grep --color=auto -P '^[\s0-9]+' | tac | less -r
    else
        local args="$@"
        history | grep --color=auto -E "$args" | tac | less -r
    fi
}

# 'uniq' doesn't actually make things unique....
alias dedupe='uniq'
alias unique='sort | uniq'

alias fame='find . -name'

alias filecount='ls -l | wc -l'

# so you don't have to CD into the path or re-type it
rename() {
    mv $1 $(dirname $1)/$2
}

# basic xargs that works with aliases
zargs() {
    while read line; do $1 "$line" "${@:2}"; done
}

### EDITING ###

# find and edit in one go
alias vind='fame -exec vim {} \;'

finj() {
    idea $(fame "$@")
}

### CERTS ###

# import a cert
addcert() {
    if [ "$(uname)" == "Darwin" ]; then
        sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" "$@"
    else
        certutil -d sql:"$HOME"/.pki/nssdb -A -t P -n "$1" -i "$1"
    fi
}

dlcert() {
    openssl s_client -showcerts -connect $1:$2 < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $1.pem
}

alias describecert='openssl x509 -text -in'

### MAVEN ###

alias maven='mvn'
alias mvnci='mvn clean install -DskipTests -DskipITs'
alias mvnin='mvn install -DskipTests -DskipITs'

### RANDOM ###

alias repeatgif='gifsicle -bl'

pushd() {
    local UNAME=$(uname)
    if [ "$UNAME" == "Darwin" ] || [ "$UNAME" == "Linux" ]; then
        command pushd "$@" > /dev/null
    else
        command pushd "$@"
    fi
}

popd() {
    local UNAME=$(uname)
    if [ "$UNAME" == "Darwin" ] || [ "$UNAME" == "Linux" ]; then
        command popd "$@" > /dev/null
    else
        command popd "$@"
    fi
}

repeat() {
    for suffix in "${@:2}"; do
        eval "$1""$suffix"
    done
}

alias upgrate='sudo apt update && sleep 1 && sudo apt upgrade'
alias inst='sudo apt install'

restartnow() {
    local UNAME=$(uname)
    if [ "$UNAME" == "Darwin" ] || [ "$UNAME" == "Linux" ]; then
        sudo shutdown -r now
    else
        shutdown /r /t 0
    fi
}

mcat() {
    cat "$@" | more
}

lcat() {
    cat "$@" | less
}

detail() {
    local FPATH=$(which $1)
    if [ ! -z "$FPATH" ]; then
        ls -al $FPATH && file $FPATH
    fi
}

alias prettify='python -m json.tool'
