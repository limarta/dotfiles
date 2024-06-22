#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly AUTOJUMP_DIR="/tmp/autojump"
readonly AUTOJUMP_URL="https://github.com/wting/autojump.git"

function clone_autojump() {
    if [ ! -d "${AUTOJUMP_DIR}" ]; then
        git clone "${AUTOJUMP_URL}" "${AUTOJUMP_DIR}"
    fi
}

function install_autojump() {
    (cd ${AUTOJUMP_DIR} && ./install.py)
}

function uninstall_autojump() {
    echo "OOPS. No autojump uninstallation :/"
}

function main() {
    clone_autojump
    install_autojump
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
