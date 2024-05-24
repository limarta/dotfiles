#!/usr/bin/env bash

# Acknowledgement: https://github.com/shunk031/dotfiles

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

declare -r DOTFILES_REPO_URL="https://github.com/limarta/dotfiles"
declare -r BRANCH_NAME="master"
# declare -r DOTFILES_GITHUB_PAT="${DOTFILES_GITHUB_PAT:-}"

# shellcheck disable=SC2016

function get_os_type() {
    uname
}

function initialize_os_macos() {
    echo "Setup for Darwin is intentionally disabled."
    exit 1
    # function is_homebrew_exists() {
    #     command -v brew &>/dev/null
    # }

    # # Instal Homebrew if needed.
    # if ! is_homebrew_exists; then
    #     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # fi

    # # Setup Homebrew envvars.
    # if [[ $(arch) == "arm64" ]]; then
    #     eval "$(/opt/homebrew/bin/brew shellenv)"
    # elif [[ $(arch) == "i386" ]]; then
    #     eval "$(/usr/local/bin/brew shellenv)"
    # else
    #     echo "Invalid CPU arch: $(arch)" >&2
    #     exit 1
    # fi
}

function initialize_os_linux() {
    :
}

function initialize_os_env() {
    local ostype
    ostype="$(get_os_type)"

    if [ "${ostype}" == "Darwin" ]; then
        initialize_os_macos
    elif [ "${ostype}" == "Linux" ]; then
        initialize_os_linux
    else
        echo "Invalid OS type: ${ostype}" >&2
        exit 1
    fi
}

function run_chezmoi() {
    # download the chezmoi binary from the URL
    sh -c "$(curl -fsLS get.chezmoi.io)"
    local chezmoi_cmd
    chezmoi_cmd="./bin/chezmoi"
    echo "${DOTFILES_REPO_URL}"

    # if is_ci_or_not_tty; then
    #     no_tty_option="--no-tty" # /dev/tty is not available (especially in the CI)
    # else
    #     no_tty_option="" # /dev/tty is available OR not in the CI
    # fi
    # run `chezmoi init` to setup the source directory,
    # generate the config file, and optionally update the destination directory
    # to match the target state.
    "${chezmoi_cmd}" init "${DOTFILES_REPO_URL}" \
        --force \
        --branch "${BRANCH_NAME}" \
        --use-builtin-git true \
        # ${no_tty_option}

    # the `age` command requires a tty, but there is no tty in the github actions.
    # Therefore, it is currnetly difficult to decrypt the files encrypted with `age` in this workflow.
    # I decided to temporarily remove the encrypted target files from chezmoi's control.
    # if is_ci_or_not_tty; then
    #     find "$(${chezmoi_cmd} source-path)" -type f -name "encrypted_*" -exec rm -fv {} +
    # fi

    # Add to PATH for installing the necessary binary files under `$HOME/.local/bin`.
    export PATH="${PATH}:${HOME}/.local/bin"

    # run `chezmoi apply` to ensure that target... are in the target state,
    # updating them if necessary.
    "${chezmoi_cmd}" apply 

    # purge the binary of the chezmoi cmd
    # rm -fv "${chezmoi_cmd}"
}

function initialize_dotfiles() {

    # if ! is_ci_or_not_tty; then
    #     # - /dev/tty of the github workflow is not available.
    #     # - We can use password-less sudo in the github workflow.
    #     # Therefore, skip the sudo keep alive function.
    #     keepalive_sudo
    # fi
    run_chezmoi
}

function main() {
    local -r DOTFILES_LOGO='
                          /$$                                      /$$
                         | $$                                     | $$
     /$$$$$$$  /$$$$$$  /$$$$$$   /$$   /$$  /$$$$$$      /$$$$$$$| $$$$$$$
    /$$_____/ /$$__  $$|_  $$_/  | $$  | $$ /$$__  $$    /$$_____/| $$__  $$
   |  $$$$$$ | $$$$$$$$  | $$    | $$  | $$| $$  \ $$   |  $$$$$$ | $$  \ $$
    \____  $$| $$_____/  | $$ /$$| $$  | $$| $$  | $$    \____  $$| $$  | $$
    /$$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$/| $$$$$$$//$$ /$$$$$$$/| $$  | $$
   |_______/  \_______/   \___/   \______/ | $$____/|__/|_______/ |__/  |__/
                                           | $$
                                           | $$
                                           |__/

             *** This is setup script for my dotfiles setup ***            
                     https://github.com/limarta/dotfiles
'
    echo "$DOTFILES_LOGO"
    
    initialize_os_env
    initialize_dotfiles
}
main