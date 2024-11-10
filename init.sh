#!/usr/bin/env sh

########
# VARS #
########

SRCDIR="$HOME/Source"
MEDIADIR="$HOME/Media"
CURDIR=$(pwd)

DOOMSRC=$(pwd)/doom.d
NIXSRC=$(pwd)/configuration.nix
I3SRC=$(pwd)/config
ZSHRCSRC=$(pwd)/zshrc

DOOMDIR="$HOME/.doom.d"
NIXCFG="/etc/nixos/configuration.nix"
I3CFG="$HOME/.config/i3/config"
ZSHRC="$HOME/.zshrc"

#####################
# ARRANGE MEDIA DIR #
#####################

if ! [ -d "$SRCDIR" ]; then
    mkdir "$SRCDIR"
fi

if ! [ -d "$MEDIADIR" ]; then
    mkdir "$MEDIADIR"
fi

moveifexists() {
    # $1 Source
    # $2 Destination
    if [ -d "$1" ]; then
        if [ -d "$2" ]; then
            cp -rf "$1/**" "$2"
            rm -rf "$1"
        else
            mv "$1" "$2"
        fi
    elif ! [ -d "$2" ]; then
        mkdir "$2"
    fi
}

moveifexists "$HOME/Pictures" "$MEDIADIR/Pictures"
moveifexists "$HOME/Music" "$MEDIADIR/Music"
moveifexists "$HOME/Videos" "$MEDIADIR/Videos"

###############
# SETUP LINKS #
###############

ln -s "$DOOMSRC" "$DOOMDIR"
ln -s "$NIXSRC" "$NIXCFG"
ln -s "$I3SRC" "$I3CFG"
ln -s "$ZSHRCSRC" "$ZSHRC"
