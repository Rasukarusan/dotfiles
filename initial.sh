#!/usr/bin/env bash

exists() {
    type "$1" >/dev/null 2>&1
}

# Install Homebrew
if exists breww ; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install Ansible
if exists ansible ; then
    brew install ansible
    cd ansible && ansible-playbook -i inventory/localhost localhost.yml
fi
