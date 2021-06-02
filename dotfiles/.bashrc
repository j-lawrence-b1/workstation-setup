# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

if [[ -z $BASHRC_RUN ]]; then

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# WSL bash doen't run .profile on login. Fix that.
if grep -qsEi "(Microsoft|WSL)" /proc/version; then
    # include .profile if it exists
    if [ -f "$HOME/.profile" ]; then
	    . "$HOME/.profile"
    fi
    # Make WSL and Docker Desktop for Windows play nice.
    # This assumes that the docker_relay container is running.
    export DOCKER_HOST=tcp://localhost:23750
    pdir=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | sed 's/.*\\//g')
    WHOME=/mnt/c/Users/$pdir
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

export EDITOR=/usr/bin/vim

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# NOTE: Everything above is more-or-less copied straight from /etc/skel/.bashrc

#######################
# BEGIN my stuff
#######################
#export TF_PLUGIN_CACHE_DIR=$HOME/.terraform
#export TF_LOG=INFO

# Start an ssh tunnel: Obsolete, but left as a reference.
#alias eltunnel="ssh -L 4003:localhost:4000 EC-LN0028"
#alias ttunnel="ssh -NL 8850:localhost:8850 cdr.everlaw.com"

# Run jupyter-notebook as a server. After access the server from
# the Firefox on windows as localhost:8888
alias jnb="jupyter-notebook --no-browser"

alias cls=clear
alias h=history

# Edit the bash history with vi!
function hed () {
    history -w
    cp ~/.bash_history ~/.bash_history.bak
    vi ~/.bash_history
    history -c
    history -r ~/.bash_history
}

# Add ssh keys to the linux keychain.
function chainme () {
    /usr/bin/keychain ~/.ssh/*_rsa
    . ~/.keychain/${HOSTNAME}-sh
}

function awslogin () {
    local profile=${1:-terraform}

    bash ~/.local/bin/set_aws_session.sh -p $profile
    . ~/.aws/set_aws_env.sh
}

function rebash () {
    unset BASHRC_RUN
    . ~/.bashrc
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('${HOME}/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "${HOME}/miniconda3/etc/profile.d/conda.sh" ]; then
        . "${HOME}/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="${HOME}/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH=$HOME/.local/bin:$PATH

# Get a fancy prompt when inside a git repo.
if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_ONLY_IN_REPO=1
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWUPSTREAM=1
    GIT_PROMPT_THEME_NAME=TruncatedPwd_WindowTitle_Ubuntu.bgptheme
    source $HOME/.bash-git-prompt/gitprompt.sh
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(__git_ps1 " (%s)")\[\033[00m\]\$ '
    #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 " (%s)")\$ '
fi
unset color_prompt force_color_prompt

if [[ -n "$CONDA_EXE" ]]; then
    conda activate base
fi

# end if [[ -z BASHRC_RUN ]]
fi
BASHRC_RUN=1
