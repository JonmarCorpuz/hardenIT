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

# ==== HARDEN PAM ===========================================================================

# Ensure password unlock time is configured
if ls -l /etc/security/faillock.conf &> /dev/null;
then
    if ! grep -Pi -- '^\h*unlock_time\h*=\h*(0|9[0-9][0-9]|[1-9][0-9]{3,})\b' /etc/security/faillock.conf &> /dev/null;
    then
        echo -e "${RED}[FAIL]${WHITE} unlock_time is not properly set according to the CIS Benchmark"
    
        if [[ $commitEnabled = "true" ]];
        then 
            echo -e "* ${YELLOW}[WARNING]${WHITE} Modifying the unlock_time parameter in /etc/security/faillock.conf to conform with the CIS Benchmark"
            echo "unlock_time = 900" >> /etc/security/faillock.conf &> /dev/null
            echo -e "${GREEN}[SUCCESS]${WHITE} unlock_time successfully changed to 900"
            echo -e "* ${YELLOW}[WARNING]${WHITE} Removing the unlock_time argument from the pam_faillock.so module in the PAM files"
            grep -Pl -- '\bpam_faillock\.so\h+([^#\n\r]+\h+)?unlock_time\b' /usr/share/pam-configs/* 
            echo -e "${GREEN}[SUCCESS]${WHITE} "
        fi

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> unlock_time either isn't specified or isn't equal to either 0 or 900"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> unlock should be equal to either 0 or 900"
        fi 
    else
    echo -e "${GREEN}[PASS]${WHITE} Password unlock time conforms with the CIS Benchmark"   
    fi
else 
    echo -e "${RED}[ERROR]${WHITE} /etc/security/faillock.conf wasn't be found"
fi 