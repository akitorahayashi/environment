#!/bin/bash
# Managed Python CLIs

# Aider
alias ai='aider.py'
ai-st() {
    local _output
    if ! _output="$(aider.py set-model "$1")"; then
        return $?
    fi
    eval "$_output"
}
ai-us() {
    local _output
    if ! _output="$(aider.py unset-model)"; then
        return $?
    fi
    eval "$_output"
}
alias ai-ls='aider.py list-models'

# SSH Manager
alias ssh-gk='ssh_manager.py gk'
alias ssh-ls='ssh_manager.py ls'
alias ssh-rm='ssh_manager.py rm'
