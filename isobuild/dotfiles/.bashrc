# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.dotnet:$PATH"
export PATH="$HOME/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"