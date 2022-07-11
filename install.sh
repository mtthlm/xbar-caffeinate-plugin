#!/usr/bin/env bash
# shellcheck shell=bash

# Declare and assign separately to avoid masking return values.
# shellcheck disable=SC2155

set -o errexit -o nounset

readonly PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGINS_DIR="$(dirname "$PLUGIN_DIR")" \
         PLUGIN_NAME="$(basename "$PLUGIN_DIR")"
readonly PLUGIN_SCRIPT="./${PLUGIN_NAME}/plugin.sh" \
         PLUGIN_REFRESH_TIME="${1:-"5s"}"

ln -sfv "$PLUGIN_SCRIPT" "${PLUGINS_DIR}/${PLUGIN_NAME}.${PLUGIN_REFRESH_TIME}.${PLUGIN_SCRIPT##*.}"
