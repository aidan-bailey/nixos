#!/usr/bin/env sh

########
# VARS #
########

# Determine host name from environment only
DETECTED_HOST="${HOSTNAME:-${HOST:-}}"
if [ -z "$DETECTED_HOST" ]; then
    echo "Error: HOSTNAME/HOST not set in environment"
    echo "Set HOSTNAME or HOST to the short hostname and re-run."
    exit 1
fi
# use short name (strip domain)
HOSTNAME=${DETECTED_HOST%%.*}

HOSTDIR="hosts/$HOSTNAME"

# Validate that the host directory exists
if [ ! -d "$HOSTDIR" ]; then
    echo "Error: Host directory '$HOSTDIR' does not exist"
    echo "Available hosts:"
    ls -1 hosts/ 2>/dev/null || echo "No hosts directory found"
    exit 1
fi

echo "Configuring system for host: $HOSTNAME"

SRCDIR="$HOME/Source"
MEDIADIR="$HOME/Media"
CURDIR=$(pwd)

NIXCFG=$(pwd)/$HOSTDIR/configuration.nix
I3CFG=$(pwd)/configs/config
ZSHRC=$(pwd)/configs/zshrc
HOMECFG=$(pwd)/home.nix
FLAKECFG=$(pwd)/flake.nix
HARDWARECFG=/etc/nixos/hardware-configuration.nix
HARDWARECFGSRC=$(pwd)/$HOSTDIR/hardware-configuration.nix

NIXTRG="/etc/nixos/configuration.nix"
FLAKETRG="/etc/nixos/flake.nix"
HARDWARETRG="$HOME/System/$HOSTDIR/hardware-configuration.nix"
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

sudo ln -sfn "$NIXCFG" "$NIXTRG"
sudo ln -sfn "$FLAKECFG" "$FLAKETRG"

if ! [ -f "$HARDWARETRG" ]; then
    sudo cp -f "$HARDWARECFGSRC" "$HARDWARETRG"
    sudo ln -sfn "$HARDWARETRG" "$HARDWARECFG"
fi

ln -sfn "$I3CFG" "$I3CFGTRG"
ln -sfn "$ZSHRC" "$ZSHRCTRG"
mkdir -p "$HOME/.config/home-manager"
#ln -s "$HOMECFG" "$HOMECFGTRG"

echo "Configuration complete"

################
# HOME MANAGER #
################
