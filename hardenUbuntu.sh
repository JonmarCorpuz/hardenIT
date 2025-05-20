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
  echo "" && echo -e "${RED}[ERROR]${WHITE} Usage: ./hardenUbuntu.sh [--commit|--difference]" && echo ""
  exit 1
}

# ==== VERIFICATIONS ========================================================================
while [[ "$#" -gt 0 ]];
do

  case "$1" in

    # Commit flag (Applique les paramètres)
    --commit)
      sed -i "s/^commitEnabled=.*/commitEnabled=true/" ./Files/settings.conf
      sed -i "s/^flagUsed=.*/flagUsed=true/" ./Files/settings.conf
      ;;

    # Difference flag (Affiche seulement les paramètres dont la valeur est différente du fichier de configuration)
    --difference)
      sed -i "s/^differenceEnabled=.*/differenceEnabled=true/" ./Files/settings.conf
      sed -i "s/^flagUsed=.*/flagUsed=true/" ./Files/settings.conf
      ;;

    # Invalid option
    *)
      usageError
      ;;

  esac
  shift

done

# ==== REQUIREMENTS =========================================================================
sudo chmod +x ./Scripts/*

# ==== MAIN BODY ============================================================================

echo ""

if [[ $CRON_HARDENING =~ true ]];
then
  echo -e "${GREY}[NOTICE]${WHITE} Hardening cron"
  ./Scripts/hardenCron.sh
  echo ""
fi

if [[ $SSH_HARDENING =~ true ]];
then
  echo -e "${GREY}[NOTICE]${WHITE} Hardening SSH"
  ./Scripts/hardenSSH.sh
  echo ""
fi 

if [[ $PROCESS_HARDENING =~ true ]];
then
  echo -e "${GREY}[NOTICE]${WHITE} Hardening processes"
  ./Scripts/hardenProcesses.sh
  echo ""
fi

if [[ $PAM_HARDENING =~ true ]];
then
  echo -e "${GREY}[NOTICE]${WHITE} Hardening PAM"
  ./Scripts/hardenPAM.sh
  echo ""
fi

if [[ $BOOTLOADER_HARDENING =~ true ]];
then
  echo -e "${GREY}[NOTICE]${WHITE} Hardening the bootloader"
  ./Scripts/hardenBootloader.sh
  echo ""
fi

if [[ $NETWORK_HARDENING =~ true ]];
then
  echo -e "${GREY}[NOTICE]${WHITE} Hardening the network"
  ./Scripts/hardenNetwork.sh
  echo ""
fi

echo -e "${GREEN}[SUCCESS]${WHITE} Script executed with success"
sed -i "s/^commitEnabled=.*/commitEnabled=false/" ./Files/settings.conf
sed -i "s/^differenceEnabled=.*/differenceEnabled=false/" ./Files/settings.conf
sed -i "s/^flagUsed=.*/flagUsed=false/" ./Files/settings.conf
exit 0