#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_julia() {
    # Install rust using rustup
    # ref. https://www.rust-lang.org/tools/install
    # curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    curl -fsSL https://install.julialang.org | sh
}

function uninstall_julia() {
    juliaup self uninstall
}

function main() {
    install_julia
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi