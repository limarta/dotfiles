#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_rye() {
    curl -sSf https://rye.astral.sh/get | bash
}

function uninstall_rye() {
    rye self uninstall
}

function main() {
    install_rye
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi