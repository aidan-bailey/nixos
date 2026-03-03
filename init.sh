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


#mkdir -p "$HOME/.config/home-manager"

echo "Configuration complete"
