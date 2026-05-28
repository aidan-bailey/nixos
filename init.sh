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


#############
# SOPS KEY #
#############

# Derive the sops user age key from the user's SSH ed25519 key so that
# home-manager can decrypt secrets/home.yaml on the first nixos-rebuild.
SOPS_AGE_DIR="$HOME/.config/sops/age"
SOPS_AGE_KEY="$SOPS_AGE_DIR/keys.txt"
SSH_KEY="$HOME/.ssh/$HOSTNAME"

if [ -f "$SOPS_AGE_KEY" ]; then
    echo "sops user age key already present at $SOPS_AGE_KEY"
elif [ ! -f "$SSH_KEY" ]; then
    echo "Warning: $SSH_KEY not found; skipping sops age key setup."
    echo "Generate one with: ssh-keygen -t ed25519 -f $SSH_KEY"
    echo "Then re-run init.sh."
else
    echo "Deriving sops user age key from $SSH_KEY"
    mkdir -p "$SOPS_AGE_DIR"
    if command -v ssh-to-age >/dev/null 2>&1; then
        ssh-to-age -private-key -i "$SSH_KEY" > "$SOPS_AGE_KEY"
    else
        nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i '$SSH_KEY'" > "$SOPS_AGE_KEY"
    fi
    chmod 600 "$SOPS_AGE_KEY"
    echo "Wrote $SOPS_AGE_KEY"
fi


#mkdir -p "$HOME/.config/home-manager"

echo "Configuration complete"
