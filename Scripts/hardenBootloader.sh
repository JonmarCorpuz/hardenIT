#!/usr/bin/env bash

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

# ==== HARDEN BOOTLOADER ====================================================================

# Ensure access to bootloader config is configured
if ls -l /boot/grub/grub.cfg $&> /dev/null;
then
  bootloaderPermissionCheck=$(stat -Lc 'Access: (%#a/%A)  Uid: ( %u/ %U) Gid: ( %g/ %G)' /boot/grub/grub.cfg)
  if [[ $bootloaderPermissionCheck != *"0600/-rw-------"* && $bootloaderPermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} Permissions for /boot/grub/grub.cfg doesn't conform with the CIS Benchmark"

    if [[ $commitEnabled = "true" ]];
    then
      echo -e "${YELLOW}[WARNING]${WHITE} Modifying permissions for /boot/grub/grub.cfg to conform with the CIS Benchmark" 
      sudo chown root:root /boot/grub/grub.cfg &> /dev/null
      sudo chmod u-x,go-rwx /boot/grub/grub.cfg &> /dev/null
    fi

    if [[ $differenceEnabled = "true" ]];
    then
      echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /boot/grub/grub.cfg ---> $bootloaderPermissionCheck"
      echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /boot/grub/grub.cfg --> Access: (0600/-rw-------)  Uid: ( 0/ root) Gid: ( 0/ root)"
    fi
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /boot/grub/grub.cfg conform with the CIS Benchmark"
  fi
else
  echo -e "${RED}[ERROR]${WHITE} /boot/grub/grub.cfg was not found"
fi