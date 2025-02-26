#!/bin/bash

cd "$(readlink -f "$(dirname "$0")")" || exit 1

while [[ $# -gt 0 ]]; do
    case "$1" in
        no-build)
            skip_build=y
            shift
        ;;
        no-keymap)
            skip_keymap=y
            shift
        ;;
        no-install)
            skip_install=y
            shift
        ;;
        no-tag)
            skip_tag=y
            shift
        ;;
    esac
done

# Check if git repo is clean.
# Dont care about what changes there are, so just check for non-empty
# Also redirect errors to reduce chance for false positives.
if [[ -z "$(git status --porcelain 2>&1)" ]]; then
    branch="$(git branch --show-current)"
    commit="$(git rev-parse --short HEAD)"
    if [[ -n $branch ]]; then
        keymapname="keymap/${branch}-${commit}.svg"
    else
        keymapname="keymap/${commit}.svg"
    fi
else
    while true; do
        read -rp "Worktree is not clean. Continue with wip build? (y/N) " choice
        case "$choice" in
            (Y|y|[Yy][Ee][Ss])
                timestamp="$(date -Iseconds)"
                keymapname="keymap/${timestamp}-wip.svg"
                break
            ;;
            (''|N|n|[Nn][Oo])
                exit 1
            ;;
            (*)
                continue
            ;;
        esac
    done
fi

if [[ -z $skip_build ]]; then
    if ! ./build.sh; then
        exit 1
    fi

    printf '\n\n\n'
fi

if [[ -z $skip_install ]]; then
    if ! ./install.sh; then
        echo 'did not install completely, aborting' >&2
        exit 1
    fi
fi

if [[ -z $skip_keymap ]]; then
    keymapfile=''
    if keymapfile="$(./drawkeymap.sh "$keymapname")"; then
        echo "made keymap $keymapfile" >&2
        ln --symbolic --force "$keymapfile" keymap.svg \
            && echo "linked keymap.svg to $keymapfile"
    else
        echo "failed making keymap $keymapfile" >&2
    fi
fi

if [[ -z $skip_tag ]]; then
    oldTag="$(git rev-parse --short prev-install)"

    if [[ $(git tag --list install) = install ]]; then
        newTag="$(git rev-parse --short install)"
        git tag --force prev-install install >/dev/null && git tag --delete install >/dev/null
    else
        newTag="$(git rev-parse --short install-wip)"
        git tag --force prev-install install-wip >/dev/null && git tag --delete install >/dev/null
    fi \
        && printf "old old: %s\nnew old: %s\n" "$oldTag" "$newTag"

    if [[ -n $commit ]]; then
        git tag install "$commit" >/dev/null \
            && echo "new new: $(git rev-parse --short install)"
    else
        git tag install-wip HEAD >/dev/null \
            && echo "new new: $(git rev-parse --short install-wip)"
    fi
fi

