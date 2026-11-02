#!/usr/bin/env bash
#
# run.sh - Abre o Mac Fan (app GTK para controlar a ventoinha do Mac mini
#          rodando Linux). Use `install.sh` uma vez antes.
#

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "install" ]]; then
  shift
  exec "${DIR}/install.sh" "$@"
fi

exec "${DIR}/mac-fan" "$@"
