#!/bin/bash

# requires to setup gloves to automount to these paths (and let you write to them)
rightname=GLV80RHBOOT
rightpath="$XDG_RUNTIME_DIR"/mount/gloveR
leftname=GLV80LHBOOT
leftpath="$XDG_RUNTIME_DIR"/mount/gloveL
src=glove80.uf2
dst=CURRENT.uf2

if [[ ! -r $src ]]; then
    echo "cannot read $src" >&2
    exit 1
fi

function install {
    echo "waiting for $1 to be available" >&2
    until [[ -e "/dev/disk/by-label/$1" ]]; do
        sleep 1
    done

    echo "mounting $2" >&2
    mkdir --parents "$2" || return 1
    mount "$2" || return 1

    local path
    path="$2/$3"

    if cp -v "$src" "$path" >&2; then
        printf ok
    else
        echo "failed writing to $path" >&2
        printf failure

        echo "unmounting $2" >&2
        umount "$2"

        return 1
    fi

    echo "unmounting $2" >&2
    umount "$2"
}

doright=n
doleft=n
until [[ $# = 0 ]]; do
    case "$1" in
        r|R|right)
            doright=y
            shift
        ;;
        l|L|left)
            doleft=y
            shift
        ;;
        *)
            shift
        ;;
    esac
done

case "$doleft$doright" in
    yy|nn)
        right="$(install "$rightname" "$rightpath" "$dst")"
        left="$(install "$leftname" "$leftpath" "$dst")"
        echo "left: $left, right: $right"
        if [[ $left != ok || $right != ok ]]; then
            exit 1
        fi
    ;;
    yn)
        left="$(install "$leftname" "$leftpath" "$dst")"
        echo "left: $left, right: skip"
        if [[ $left != ok ]]; then
            exit 1
        fi
    ;;
    ny)
        right="$(install "$rightname" "$rightpath" "$dst")"
        echo "left: skip, right: $right"
        if [[ $right != ok ]]; then
            exit 1
        fi
    ;;
esac

