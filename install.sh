#!/bin/bash

# requires to setup gloves to automount to these paths (and let you write to them)
rightpath=/mnt/gloveR
leftpath=/mnt/gloveL
src=glove80.uf2
dst=CURRENT.uf2

if [[ ! -r $src ]]; then
    echo "cannot read $src" >&2
    exit 1
fi

function install {
    read -rsp "Press enter when $1 half is in bootloader mode"$'\n'
    mount "$2"
    path="$2/$3"
    if cp -v "$src" "$path" >&2; then
        printf ok
    else
        echo "failed writing to $path" >&2
        printf failure
        return 1
    fi
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
        right="$(install right "$rightpath" "$dst")"
        left="$(install left "$leftpath" "$dst")"
        echo "$left $right"
        if [[ $left != ok || $right != ok ]]; then
            exit 1
        fi
    ;;
    yn)
        left="$(install left "$leftpath/$dst")"
        echo "$left skip"
        if [[ $left != ok ]]; then
            exit 1
        fi
    ;;
    ny)
        right="$(install right "$rightpath/$dst")"
        echo "skip $right"
        if [[ $right != ok ]]; then
            exit 1
        fi
    ;;
esac

