#!/bin/bash
set -euo pipefail

VERSION="${PARAM_VERSION}"
CHANNEL="${PARAM_CHANNEL:-stable}"
DISABLE_METRICS="${PARAM_DISABLE_METRICS:-false}"
RETRIES="${PARAM_RETRIES:-3}"
PROXY="${PARAM_PROXY:-}"
TRUSTED_ENVS="${PARAM_TRUSTED_ENVS:-}"
EXTRA_NIX_CONFIG="${PARAM_EXTRA_NIX_CONFIG:-}"
EXTRA_SUBSTITUTERS="${PARAM_EXTRA_SUBSTITUTERS:-}"
EXTRA_SUBSTITUTER_KEYS="${PARAM_EXTRA_SUBSTITUTER_KEYS:-}"
DISABLE_UPGRADE="${PARAM_DISABLE_UPGRADE:-true}"
EXTRA_FLOX_CONFIG="${PARAM_EXTRA_FLOX_CONFIG:-}"

FLOX_SUBSTITUTER="https://cache.flox.dev"
FLOX_PUBLIC_KEY="flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="

# ── Set metrics ─────────────────────────────────────────
export FLOX_DISABLE_METRICS="$DISABLE_METRICS"

# ── Sudo helper ─────────────────────────────────────────
SUDO=''
if [ "$EUID" -ne 0 ]; then
  SUDO='sudo'
fi

# ── Proxy setup ─────────────────────────────────────────
PROXY_ARGS=""
if [ -n "$PROXY" ]; then
  PROXY_ARGS="--proxy $PROXY"
  export HTTPS_PROXY="$PROXY"
  export HTTP_PROXY="$PROXY"
  export ALL_PROXY="$PROXY"
  echo "Using proxy: $PROXY"
fi

# ── Configure Nix substituter ──────────────────────────
configure_nix_substituter() {
  local nix_conf="/etc/nix/nix.conf"
  $SUDO mkdir -p /etc/nix

  if [ -f "$nix_conf" ] && grep -q "$FLOX_SUBSTITUTER" "$nix_conf"; then
    echo "Flox substituter already configured"
    return
  fi

  $SUDO bash -c "cat >> $nix_conf" <<NIXCONF

# Added by flox-orb
extra-trusted-substituters = $FLOX_SUBSTITUTER
extra-trusted-public-keys = $FLOX_PUBLIC_KEY
NIXCONF
  echo "Configured Flox substituter in $nix_conf"
}

# ── Install via existing Nix ───────────────────────────
install_via_nix() {
  echo "Nix detected - installing Flox via nix profile install"
  configure_nix_substituter

  nix profile install \
    --experimental-features "nix-command flakes" \
    --extra-substituters "$FLOX_SUBSTITUTER" \
    --extra-trusted-public-keys "$FLOX_PUBLIC_KEY" \
    --accept-flake-config \
    "github:flox/flox/latest"

  flox --version
  echo "Flox installed successfully via existing Nix"
}

# ── Install via package download ───────────────────────
install_via_package() {
  local os_family
  local os_arch
  os_family=$(uname -s | tr '[:upper:]' '[:lower:]')
  os_arch=$(uname -m | tr '[:upper:]' '[:lower:]')

  local download_url="https://downloads.flox.dev"
  case $CHANNEL in
    stable|qa|nightly)
      download_url="$download_url/by-env/$CHANNEL"
      ;;
    *)
      download_url="$download_url/by-commit/$CHANNEL"
      ;;
  esac

  local version_suffix=""
  if [ -n "$VERSION" ]; then
    version_suffix="-$VERSION"
  fi

  case $os_family in
    darwin)
      case $os_arch in
        arm64)
          download_url="$download_url/osx/flox${version_suffix}.aarch64-darwin.pkg"
          ;;
        x86_64)
          download_url="$download_url/osx/flox${version_suffix}.x86_64-darwin.pkg"
          ;;
        *)
          echo "Unsupported architecture: $os_arch"
          exit 3
          ;;
      esac
      ;;
    linux)
      local installer_type
      if command -v dpkg >/dev/null; then
        installer_type="deb"
      elif command -v rpm >/dev/null; then
        installer_type="rpm"
      else
        echo "Neither dpkg nor rpm found."
        exit 4
      fi
      case $os_arch in
        aarch64|arm64)
          download_url="$download_url/$installer_type/flox${version_suffix}.aarch64-linux.$installer_type"
          ;;
        x86_64)
          download_url="$download_url/$installer_type/flox${version_suffix}.x86_64-linux.$installer_type"
          ;;
        *)
          echo "Unsupported architecture: $os_arch"
          exit 3
          ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $os_family"
      exit 2
      ;;
  esac

  echo "Downloading flox from $download_url ..."

  local downloaded_file
  downloaded_file=$(mktemp -d -t "tmp.flox-orb-XXXXXXXX")/$(basename "$download_url")
  # shellcheck disable=SC2086
  curl --user-agent "flox-orb" \
      $PROXY_ARGS \
      --retry "$RETRIES" \
      --retry-delay 5 \
      --retry-all-errors \
      "$download_url" \
      --output "$downloaded_file"

  echo "Installing flox..."

  local retry_delay=5
  for attempt in $(seq 1 "$RETRIES"); do
    echo "Installation attempt $attempt of $RETRIES..."
    if install_package "$downloaded_file"; then
      echo "Installation succeeded on attempt $attempt"
      break
    else
      if [ "$attempt" -eq "$RETRIES" ]; then
        echo >&2 "Installation failed after $RETRIES attempts"
        exit 1
      fi
      echo "Retrying in ${retry_delay}s..."
      sleep "$retry_delay"
    fi
  done

  rm -f "$downloaded_file"

  flox --version
  echo "Flox installed successfully via package"
}

install_package() {
  local file="$1"
  case $file in
    *.rpm)
      $SUDO rpm -i --notriggers "$file"
      ;;
    *.deb)
      $SUDO dpkg -i --no-triggers "$file"
      ;;
    *.pkg)
      $SUDO installer -pkg "$file" -target /
      ;;
    *)
      echo >&2 "Unknown file type: $file"
      exit 1
      ;;
  esac
}

# ── Post-install configuration ─────────────────────────
configure_post_install() {
  local nix_conf="/etc/nix/nix.conf"

  # Extra nix config
  if [ -n "$EXTRA_NIX_CONFIG" ]; then
    $SUDO mkdir -p /etc/nix
    echo "$EXTRA_NIX_CONFIG" | $SUDO tee -a "$nix_conf" >/dev/null
    echo "Applied extra nix config"
  fi

  # Extra substituters
  if [ -n "$EXTRA_SUBSTITUTERS" ]; then
    $SUDO mkdir -p /etc/nix
    {
      echo "extra-trusted-substituters = $EXTRA_SUBSTITUTERS"
      if [ -n "$EXTRA_SUBSTITUTER_KEYS" ]; then
        echo "extra-trusted-public-keys = $EXTRA_SUBSTITUTER_KEYS"
      fi
    } | $SUDO tee -a "$nix_conf" >/dev/null
    echo "Added extra substituters"
  fi

  # Trusted environments
  if [ -n "$TRUSTED_ENVS" ]; then
    IFS=',' read -ra envs <<< "$TRUSTED_ENVS"
    for env in "${envs[@]}"; do
      env=$(echo "$env" | xargs)
      if [ -n "$env" ]; then
        flox config --set "trusted_environments.\"$env\"" trust
        echo "Trusted environment: $env"
      fi
    done
  fi

  # Disable upgrade notifications
  if [ "$DISABLE_UPGRADE" = "true" ]; then
    flox config --set upgrade_notifications false
    echo "Upgrade notifications disabled"
  fi

  # Extra flox config
  if [ -n "$EXTRA_FLOX_CONFIG" ]; then
    while IFS= read -r line; do
      line=$(echo "$line" | xargs)
      if [ -n "$line" ] && [[ "$line" == *"="* ]]; then
        local key="${line%%=*}"
        local value="${line#*=}"
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        flox config --set "$key" "$value"
        echo "Flox config: $key = $value"
      fi
    done <<< "$EXTRA_FLOX_CONFIG"
  fi
}

# ── Main ───────────────────────────────────────────────
if command -v nix >/dev/null 2>&1; then
  install_via_nix
else
  install_via_package
fi

configure_post_install
