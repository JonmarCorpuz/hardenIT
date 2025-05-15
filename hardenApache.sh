#!/bin/bash

# ==== STATIC VARIABLES =====================================================================
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
GREY="\033[38;5;254m"

set -o allexport
source ./Files/staticVariables.env
source ./Files/settings.conf
set +o allexport

# ==== FUNCTIONS ============================================================================
usageError() {
  echo "" && echo -e "${RED}[ERROR]${WHITE} Usage: ./hardenApache.sh [--commit|--difference]" && echo "" 
  exit 1
}
