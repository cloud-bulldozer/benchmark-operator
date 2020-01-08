# .bashrc

# setting the ls command output colorize
export CLICOLOR=1

# Setting up the Prompt
export PS1="\u@\h\e[0;31m[\W]\e[m # "

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -l'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

