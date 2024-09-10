#!/bin/bash

VERSION="${PARAM_VERSION}"
CHANNEL="${PARAM_CHANNEL:-stable}"

OS_FAMILY=$(uname -s | tr '[:upper:]' '[:lower:]')
OS_ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')


DOWNLOAD_URL="https://downloads.flox.dev"
case $CHANNEL in
  stable|qa|nightly) DOWNLOAD_URL="$DOWNLOAD_URL/by-env/$CHANNEL" ;;
  *) DOWNLOAD_URL="$DOWNLOAD_URL/by-commit/$CHANNEL" ;;
esac

if [ "$VERSION" != "" ]; then
  VERSION="-$VERSION"
fi

case $OS_FAMILY in
  darwin)
    case $OS_ARCH in
      arm64)  DOWNLOAD_URL="$DOWNLOAD_URL/osx/flox$VERSION.aarch64-darwin.pkg" ;;
      x86_64) DOWNLOAD_URL="$DOWNLOAD_URL/osx/flox$VERSION.x86_64-darwin.pkg" ;;
      *)
        echo "Unsupported OS architecture: $OS_ARCH"
        exit 3
        ;;
    esac
    ;;
  linux)
    if [ command -v dpkg ]; then
      INSTALLER_TYPE="deb"
    elif [ command -v rpm ]; then
      INSTALLER_TYPE="rpm"
    else
      echo "Neither dpkg nor rpm package manager is available."
      exit 4
    fi
    case $OS_ARCH in
      arm64)  DOWNLOAD_URL="$DOWNLOAD_URL/$INSTALLER_TYPE/flox$VERSION.aarch64-linux.$INSTALLER_TYPE" ;;
      x86_64) DOWNLOAD_URL="$DOWNLOAD_URL/$INSTALLER_TYPE/flox$VERSION.x86_64-linux.$INSTALLER_TYPE" ;;
      *)
        echo "Unsupported OS architecture: $OS_ARCH"
        exit 3
        ;;
    esac
    ;;
  *)
    echo "Unsupported OS family: $OS_FAMILY"
    exit 2
    ;;
esac


echo "Downloading flox..."

DOWNLOADED_FILE=$(basename $DOWNLOAD_URL)
curl --user-agent "install-flox-action" \
    "$DOWNLOAD_URL" \
    --output "$DOWNLOADED_FILE";


echo "Installing flox..."

SUDO=''
if [ "$EUID" -ne 0 ]; then
  SUDO='sudo'
fi

case $DOWNLOADED_FILE in
  *.rpm)
    $SUDO rpm -i "$DOWNLOADED_FILE";
    ;;
  *.deb)
    $SUDO dpkg -i "$DOWNLOADED_FILE";
    ;;
  *.pkg)
    $SUDO installer -pkg "$DOWNLOADED_FILE" -target /;
    ;;
  *)
    echo >&2 "Aborting: Unknown file '$DOWNLOADED_FILE' downloaded. Not sure how to install it.";
    exit 1;
    ;;
esac
