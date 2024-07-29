#!/bin/bash

# creating svg from zmk-config requires keymap-drawer (install via pipx)
if keymap \
    -c <(keymap dump-config | sed -e 's/dark_mode: false/dark_mode: true/') \
    draw <(keymap parse -z ./config/glove80.keymap) \
    >"$1"
then
    echo "$1"
fi

