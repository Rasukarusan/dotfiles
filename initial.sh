#!/usr/bin/env bash

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# Install Ansible
brew install ansible
cd ansible && ansible-playbook -i inventory/localhost localhost.yml
