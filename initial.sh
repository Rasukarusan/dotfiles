#!/usr/bin/env bash

exists() {
    type "$1" >/dev/null 2>&1
}

# Install Homebrew
if ! exists brew ; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Ansible
if ! exists ansible ; then
    brew install ansible
    cd ansible
    ansible-playbook -i inventory/localhost localhost.yml --ask-become-pass
fi
