# This script should be sourced from your bash_profile!
# Edit this variable if you cloned this somewhere other than ~/Developer:

export MREAD_UTIL_BASE_PATH="$HOME/Developer/mread-util"

# Required shell variables:
# - GITHUB_USERNAME

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
    echo grep --color=always -rIE --exclude-dir=\.git "$@" . >&2
    grep --color=always -rIE --exclude-dir=\.git "$@" . | less -r
}

alias grip='grep -i'
alias gripe='gripeb 2>/dev/null'
alias igripe='gripe -i'
alias jgripe='gripe --include \*.java'
alias jigripe='jgripe -i'
alias jsgripe='gripe --include \*.js --include \*.mustache --exclude moment.js --exclude bundle.js --exclude \*.\*.js --exclude \*-min.js --exclude main.js --exclude templates.js --exclude-dir node_modules --exclude-dir testingData --exclude-dir packages'
alias jsigripe='jsgripe -i'
alias sqlgripe='gripe --include \*.sql --exclude-dir target'
alias sqligripe='sqlgripe -i'

### GIT ###

alias g='git'

alias fetch='g fetch'

alias adda='g add -A'
alias addu='g add -u'

alias push='g push'
alias pushf='g push --force-with-lease'
alias pushu='g push -u'

alias changedfiles='g diff --name-only HEAD~1'

cherry() {
    git cherry-pick "$@"
}

commit() {
    git commit -m "$@"
}

alias admit='addu && commit'

rebase() {
    fetch && g rebase "$@" origin/master
}

amend() {
    if [ "$1" == "" ]; then
        g commit --amend --no-edit
    else
        g commit --amend -m "$@"
    fi
}

alias commend='addu && amend'

alias crunch='addu && amend && fetch && rebase && pushf'

# remove all local branches except for the current one + master
gpurge() {
    git branch -l --list | grep -v '^\*' | grep -oE '[^ ]+' | grep -vE '^master$' | while read line; do git branch -D $line; done
}

alias fulldiff='git diff-index --binary'

alias master='git checkout master && git fetch && git pull'

revert() {
    git checkout HEAD~1 "$@"
}

branch() {
    git checkout -b "$@"
}

co() {
    git checkout "$@"
}

hdiff() {
    git diff HEAD
}

pruneall() {
    git reflog expire --expire=now --all
    git gc --aggressive --prune=now
}

resetmaster() {
    git reset --hard origin/master
}

alias blist='git branch -l --list'

### GITHUB ###

github_create_repo() {
    ARG1=''
    if [ "$2" == "" ]; then
        echo "Usage: github_create_repo [username] [reponame] <oneTimeCode>"
        return 1
    fi
    if [ "$3" != "" ]; then
        ARG1="X-GitHub-OTP: $3"
    fi
    ARG2="{\"name\":\"$2\"}"

    curl -u $1 -H "$ARG1" -d $ARG2 https://api.github.com/user/repos 
}

ghcr() {
    set -e
    REPONAME=$(basename "$PWD")
    github_create_repo $GITHUB_USERNAME $REPONAME $@
    touch README.md
    g init
    g add README.md
    commit 'first commit'
    g remote add origin git@github.com:$GITHUB_USERNAME/$REPONAME.git
    g push -u origin master
    set +e
}

### DOS COMPAT ###

alias cls='clear'
alias where='which'
alias tracert='traceroute'

### SHELL/UTIL HELPERS ###

killname() {
    sudo ps aux |
        grep -i "$1" |
        grep -v grep |
        awk '{print $2}' |
        while read line; do
            sudo kill -9 "$line";
        done
}

# a better version of 'history'
h() {
    if [ "$1" == "" ]; then
        history | grep --color=always -P '^[\s0-9]+' | tail -r | less -r
    else
        history | grep --color=always -E "$@" | tail -r | less -r
    fi
}

# 'uniq' doesn't actually make things unique....
alias dedupe='uniq'
alias unique='sort | uniq'

alias fame='find . -name'

# so you don't have to CD into the path or re-type it
rename() {
    mv $1 $(dirname $1)/$2
}

### EDITING ###

# find and edit in one go
alias vind='fame -exec vim {} \;'

ij() {
    if [ "$(uname)" == "Darwin" ]; then
        open -a IntelliJ\ IDEA.app
    else
        # TODO
        echo 'Not implemented for this OS.'
    fi
}

finj() {
    ij $(fame "$@")
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

alias describecert='openssl x509 -text -in'
