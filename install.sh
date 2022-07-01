#!/usr/bin/env bash -x

set -o pipefail

OSX_VERSION="$(sw_vers -productVersion)"
MINOR_VERSION=${OSX_VERSION#*.}
MAJOR_VERSION=${OSX_VERSION%.*}

KARABINER_CONF="$HOME/.karabiner.d/configuration/karabiner.json"
KARABINER_PRIV="$HOME/Library/Application Support/Karabiner/private.xml"
DEFAULT_BINDING="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

ls -l "$KARABINER_CONF" "$KARABINER_PRIV" "$DEFAULT_BINDING"

function error () {
    echo "$@" >&2
}

function verify_does_not_exist () {
    ok=true
    for file in "$@"; do
	if [[ -e "$file" ]] ; then
	    ls -l "$file"
	    error "warning: '$file' already exists; will not overwrite"
	    ok=false
	fi
    done

    if ! $ok; then
	exit 1
    fi
}

# Install Karabiner if it isn't installed, but homebrew and cask are.
if [[ "$(type -P brew)" && "$(brew tap | awk '/cask/')" ]]; then
  if [[ ! "$(brew list --cask 2>/dev/null | grep karabiner)" ]]; then
    echo "Installing Karabiner..."
    if [[ $MAJOR_VERSION -ge 11 || $MAJOR_VERSION -eq 10 && $MINOR_VERSION -ge 12 ]]; then
	brew install --cask karabiner-elements
    else
	brew install --cask karabiner
    fi
  fi
  echo "Karabiner installed."
  verify_does_not_exist "$KARABINER_CONF" "$KARABINER_PRIV"
else
  echo "Homebrew and Homebrew Cask not detected; can't install Karabiner."
  echo "If you intended for this script to install Karabiner, install"
  echo "Homebrew and Homebrew Cask:"
  echo
  echo "http://brew.sh/"
  echo "http://caskroom.io/"
  echo
  exit 1
fi

# Copy Karabiner settings.
echo "Copying Karabiner settings..."
case $MAJOR_VERSION in
     10 )
	 if [[ $MINOR_VERSION -ge 12 ]]; then
	     mkdir -p "$(dirname "$KARABINER_CONF")"
	     cp karabiner.json "$KARABINER_CONF"
	 else
	     mkdir -p "$(dirname "$KARABINER_PRIV")"
	     cp private.xml "$KARABINER_PRIV"
	 fi
	 ;;
     12)   # MJD fill this in
	 error "Installer may not support OSX version $OSX_VERSION; consult README.md"
	 error "MJD should fix this"
	 exit 1
	 mkdir -p "$(dirname "$KARABINER_PRIV")"
	 cp private.xml "$KARABINER_PRIV"
	 ;;
     * )
	 error "Installer may not support OSX version $OSX_VERSION; consult README.md"
	 exit 1
esac

# Copy DefaultKeyBinding.dict
mkdir -p ~/Library/KeyBindings
if [[ -e "$DEFAULT_BINDING" ]]; then
    error "'$DEFAULT_BINDING' already exists; will not overwrite"
else
    echo "Copying DefaultKeyBinding.dict..."
    cp DefaultKeyBinding.dict "$DEFAULT_BINDING"
fi

echo
echo "Done."
exit 0
