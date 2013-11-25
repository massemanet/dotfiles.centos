# -*- mode: shell-script -*-
# ~/.bashrc: executed by bash(1) for non-login shells.

# one path to rule them all
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

# one locale to rule them all
unset  LC_ALL
unset  LANGUAGE
unset  LC_CTYPE
export LANG=en_US.utf8

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check for GNU ls
LS=ls ; [ `which gls 2> /dev/null` ] && LS=gls

# Enable sane completion
. /etc/bash_completion

# emacs
which emacs-snapshot > /dev/null 2>&1 && EMACS=emacs-snapshot || EMACS=emacs

# find-grep
fgrep() {
    set -f
    [ -z "$1" ] && exit 1
    [ -n "$2" ] && d="$2" || d="."
    [ -n "$3" ] && n="-name $3"
    sudo find "$d" -type f $n -exec grep -iH "$1" {} \;
    set +f
}

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# fake __git_ps1
function mygitps1() {
for b in `git log --pretty=format:d' | head -1 | tr "(,)" " "`
do echo $b | awk '
/HEAD/{next}
/origin\//{next}
/tag:/{next}
{print $1}'
done | head -1
}

# find the basename of the dir that contains the current .git
mygitdir () {
    local D;
    D=`git rev-parse --git-dir 2> /dev/null`
    [ "$D" == ".git" ] && D="$PWD/$D"
    D=`dirname "$D"`
    if [ "$D" == "." ]; then
        echo "";
    elif [ "$D" == ~ ]; then
        echo "~";
    else
        basename "$D"
    fi
}

PROMPT_COMMAND='if [ $? -ne 0 ]; then ERROR_FLAG=1; else ERROR_FLAG=; fi'
if [ "$TERM" != "dumb" ]; then
    # enable color support of grep
    export GREP_OPTIONS='--color=auto'
    # enable color support of ls
    lscols=auto
    eval "`dircolors -b $HOME/.dircolors`"
    # to get emacs -nw to use 256 colors
    export TERM=xterm-256color
    # set a fancy prompt
    export GIT_PS1_SHOWSTASHSTATE=true
    export GIT_PS1_SHOWUNTRACKEDFILES=true
    export GIT_PS1_SHOWDIRTYSTATE=true

    if [ "$USER" == "root" ];then
        PS1='\[$(tput setaf 5)\]\h\[$(tput setaf 3)\]($(mygitdir):$(__git_ps1 "%s"))\[$(tput setaf 2)\]${ERROR_FLAG:+\[$(tput setaf 1)\]}#\[$(tput sgr0)\] '
    else
        PS1='\[$(tput setaf 3)\]\h\[$(tput setaf 5)\]($(mygitdir):$(__git_ps1 "%s"))\[$(tput setaf 2)\]${ERROR_FLAG:+\[$(tput setaf 1)\]}\$\[$(tput sgr0)\] '
    fi
else
    lscols=none
    PS1="\h\$ "
fi

dir()  { $LS --color=$lscols -lFh "$@";}
dirt() { dir -rt "$@";}
dird() { dir -d "$@";}
dira() { for d in "${@:-.}"; do (cd "$d";pwd; dird .*); done;}
rea()  { history | egrep "${@:-}";}
m()    { less "$@";}
e()    { $EMACS -nw "$@";}
c()    { cat "$@";}

export EDITOR=$EMACS

## history
# lots of history
export HISTSIZE=9999
export HISTFILESIZE=$HISTSIZE

# agglomerate history from multiple shells
export HISTCONTROL="ignoredups"
shopt -s histappend

PROMPT_COMMAND="$PROMPT_COMMAND;history -a"

#the below will make all commands visible in all shells
#PROMPT_COMMAND="$PROMPT_COMMAND ; history -a ; history -c; history -r"

# multi-line commands
shopt -s cmdhist

# machine-local file outside git
[ -f ~/.localbashrc ] && . ~/.localbashrc
