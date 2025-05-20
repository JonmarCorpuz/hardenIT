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

# ==== HARDEN BANNERS =======================================================================

# Ensure access to /etc/motd is configured
if ls -l /etc/motd &> /dev/null;
then
  motdPermissionCheck=$([ -e /etc/motd ] && stat -Lc 'Access: (%#a/%A)  Uid: ( %u/ %U) Gid: { %g/ %G)' /etc/motd)
  if [[ $motdPermissionCheck != *"0644/-rw-r--r--"* && $motdPermissionCheck !=  *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} Permissions for /etc/motd doesn't conform with the CIS Benchmark"

    if [[ $commitEnabled = "true" ]];
    then
      echo -e "${YELLOW}[WARNING]${WHITE} Modifying permissions for /etc/motd to conform with the CIS Benchmark"
      sudo chown root:root $(readlink -e /etc/motd) &> /dev/null
      sudo chmod u-x,go-wx $(readlink -e /etc/motd) &> /dev/null
    fi

    if [[ $differenceEnabled = "true" ]];
    then
      echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/motd ---> $motdPermissionCheck"
      echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/motd --> Access: (0644/-rw-r--r--)  Uid: ( 0/ root) Gid: ( 0/ root)"
    fi
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/motd conform with the CIS Benchmark"
  fi
else
  echo -e "${RED}[ERROR]${WHITE} /etc/motd was not found"
fi

# Ensure access to /etc/issue is configured
if ls -l /etc/issue &> /dev/null;
then
  issuePermissionCheck=$(stat -Lc 'Access: (%#a/%A)  Uid: ( %u/ %U) Gid: { %g/ %G)' /etc/issue )
  if [[ $issuePermissionCheck != *"0644/-rw-r--r--"* && $issuePermissionCheck !=  *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} Permissions for /etc/issue doesn't conform with the CIS Benchmark"

    if [[ $commitEnabled = "true" ]];
    then
      echo -e "${YELLOW}[WARNING]${WHITE} Modifying permissions for /etc/issue to conform with the CIS Benchmark"
      sudo chown root:root $(readlink -e /etc/issue) &> /dev/null
      sudo chmod u-x,go-wx $(readlink -e /etc/issue) &> /dev/null
      echo -e "${GREEN}[SUCCESS]${WHITE} Permissions for /etc/issue was successfully modified and now conform with the CIS Benchmark"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
      echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/issue ---> $issuePermissionCheck"
      echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/issue --> Access: (0644/-rw-r--r--)  Uid: ( 0/ root) Gid: ( 0/ root)"
    fi
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/issue conform with the CIS Benchmark"
  fi
else
  echo -e "${RED}[ERROR]${WHITE} /etc/issue was not found"
fi

# Ensure access to /etc/issue is configured
if ls -l /etc/issue.net &> /dev/null;
then
  issueNet_PermissionCheck=$(stat -Lc 'Access: (%#a/%A)  Uid: ( %u/ %U) Gid: { %g/ %G)' /etc/issue.net )
  if [[ $issueNet_PermissionCheck != *"0644/-rw-r--r--"* && $issueNet_PermissionCheck !=  *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} Permissions for /etc/issue doesn't conform with the CIS Benchmark"

    if [[ $commitEnabled = "true" ]];
    then
      echo -e "${YELLOW}[WARNING]${WHITE} Modifying permissions for /etc/issue.net to conform with the CIS Benchmark"
      sudo chown root:root $(readlink -e /etc/issue.net) &> /dev/null
      sudo chmod u-x,go-wx $(readlink -e /etc/issue.net) &> /dev/null
    fi

    if [[ $differenceEnabled = "true" ]];
    then
      echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/issue.net ---> $issueNet_PermissionCheck"
      echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/issue.net --> Access: (0644/-rw-r--r--)  Uid: ( 0/ root) Gid: ( 0/ root)"
    fi
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/issue.net conform with the CIS Benchmark"
  fi
else
  echo -e "${RED}[ERROR]${WHITE} /etc/issue.net was not found"
fi
