#!/usr/bin/env sh

########
# VARS #
########

SRCDIR="$HOME/Source"
MEDIADIR="$HOME/Media"
CURDIR=$(pwd)

DOOMDIR=$(pwd)/configs/doom.d
NIXCFG=$(pwd)/configuration.nix
I3CFG=$(pwd)/configs/config
ZSHRC=$(pwd)/configs/zshrc
HOMECFG=$(pwd)/home.nix

DOOMTRG="$HOME/.doom.d"
NIXTRG="/etc/nixos/configuration.nix"
I3CFGTRG="$HOME/.config/i3/config"
ZSHRCTRG="$HOME/.zshrc"
#HOMECFGTRG="$HOME/.config/home-manager/home.nix"

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

############## #
# SETUP LINKS #
###############

ln -sfn "$DOOMDIR" "$DOOMTRG"
ln -sfn "$NIXCFG" "$NIXTRG"
ln -sfn "$I3CFG" "$I3CFGTRG"
ln -sfn "$ZSHRC" "$ZSHRCTRG"
mkdir -p "$HOME/.config/home-manager"
#ln -s "$HOMECFG" "$HOMECFGTRG"

################
# HOME MANAGER #
################

