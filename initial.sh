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

# M1 Macの設定
if [ "$(uname -m)" = "arm64" ]; then
  # cocでjediを使うための設定
  sudo ln -s /opt/homebrew/bin/jedi-language-server /usr/local/bin/jedi-language-server
fi
