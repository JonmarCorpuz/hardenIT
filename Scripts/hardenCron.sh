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

# ==== HARDEN CRON ==========================================================================

cronInstalled=$(sudo systemctl list-unit-files | awk '$1~/^crond?\.service/{print $2}' &> /dev/null) # Either enabled or disabled
cronEnabled=$(sudo systemctl list-units | awk '$1~/^crond?\.service/{print $3}' &> /dev/null) # Either active or inactive

# Unmask, enable, and start cron if installed
if [[ $cronEnabled != "enabled" ]];
then
  sudo systemctl unmask "$(systemctl list-unit-files | awk '$1~/^crond?\.service/{print $1}')" &> /dev/null
  sudo systemctl --now enable "$(systemctl list-unit-files | awk '$1~/^crond?\.service/{print $1}')"  &> /dev/null
fi

crontab_PermissionCheck=$(stat -Lc 'Access: (%a/%A_ Uid: ( %u/ %U) Gid: ( %g/ %G)' /etc/crontab)
cronHourly_PermissionCheck=$(stat -Lc 'Access: (%a/%A_ Uid: ( %u/ %U) Gid: ( %g/ %G)' /etc/cron.hourly)
cronDaily_PermissionCheck=$(stat -Lc 'Access: (%a/%A_ Uid: ( %u/ %U) Gid: ( %g/ %G)' /etc/cron.daily)
cronWeekly_PermissionCheck=$(stat -Lc 'Access: (%a/%A_ Uid: ( %u/ %U) Gid: ( %g/ %G)' /etc/cron.weekly)
cronMonthly_PermissionCheck=$(stat -Lc 'Access: (%a/%A_ Uid: ( %u/ %U) Gid: ( %g/ %G)' /etc/cron.monthly)
cronD_PermissionCheck=$(stat -Lc 'Access: (%a/%A_ Uid: ( %u/ %U) Gid: ( %g/ %G)' /etc/cron.d)

# If --commit flag used
if [[ $commitEnabled = "true" ]];
then 
  if [[ $crontab_PermissionCheck != *"600/-rw-------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then 
    sudo chown root:root /etc/crontab &> /dev/null
    sudo chmod og-rwx /etc/crontab &> /dev/null
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/crontab already conform with the CIS Benchmark" 
  fi

  if [[ $cronHourly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then 
    sudo chown root:root /etc/cron.hourly/ &> /dev/null
    sudo chmod og-rwx /etc/cron.hourly/ &> /dev/null
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.hourly already conform with the CIS Benchmark" 
  fi

  if [[ $cronDaily_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    sudo chown root:root /etc/cron.daily/ &> /dev/null
    sudo chmod og-rwx /etc/cron.daily/ &> /dev/null
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.daily already conform with the CIS Benchmark" 
  fi 

  if [[ $cronWeekly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    sudo chown root:root /etc/cron.weekly/ &> /dev/null
    sudo chmod og-rwx /etc/cron.weekly/ &> /dev/null
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.weekly already conform with the CIS Benchmark" 
  fi 
  
  if [[ $cronMonthly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    sudo chown root:root /etc/cron.monthly/ &> /dev/null
    sudo chmod og-rwx /etc/cron.monthly/ &> /dev/null
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.monthly already conform with the CIS Benchmark" 
  fi 

  if [[ $cronD_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    sudo chown root:root /etc/cron.d/ &> /dev/null
    sudo chmod og-rwx /etc/cron.d/ &> /dev/null
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.d already conform with the CIS Benchmark" 
  fi 

fi

# If --difference flag used
if [[ $differenceEnabled = "true" ]];
then
  if [[ $crontab_PermissionCheck != *"600/-rw-------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then 
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/crontab don't conform with the CIS Benchmark" 
    echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/crontab ---> $crontab_PermissionCheck"
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/crontab --> Access: (600/-rw-------) Uid: ( 0/ root) Gid: ( 0/ root)"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/crontab conform with the CIS Benchmark"    
  fi

  if [[ $cronHourly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then 
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.hourly/ don't conform with the CIS Benchmark" 
    echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/cron.hourly/ ---> $cronHourly_PermissionCheck" 
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/cron.hourly/ --> Access: (700/drwx------) Uid: ( 0/ root) Gid: ( 0/ root)"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.hourly/ conform with the CIS Benchmark"
  fi

  if [[ $cronDaily_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.daily/ don't conform with the CIS Benchmark"
    echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/cron.daily/ ---> $cronDaily_PermissionCheck"
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/cron.daily ---> Access: (700/drwx------) Uid: ( 0/ root) Gid: ( 0/ root)"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.daily/ conform with the CIS Benchmark"
  fi 

  if [[ $cronWeekly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.weekly/ don't conform with the CIS Benchmark"
    echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/cron.weekly/ ---> $cronWeekly_PermissionCheck"
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/cron.weekly/ --> Access: (700/drwx------) Uid: ( 0/ root) Gid: ( 0/ root)"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.weekly/ conform with the CIS Benchmark"
  fi 

  if [[ $cronMonthly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.monthly/ don't conform with the CIS Benchmark"
    echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/cron.monthly/ ---> $cronMonthly_PermissionCheck"
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/cron.monthly/ --> Access: (700/drwx------) Uid: ( 0/ root) Gid: ( 0/ root)"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.monthly/ conform with the CIS Benchmark"
  fi 

  if [[ $cronD_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.d/ don't conform with the CIS Benchmark"
    echo -e "* ${GREY}[DEBUG]${WHITE} Current permissions for /etc/cron.d/ ---> $cronD_PermissionCheck"
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected permissions for /etc/cron.d/ --> Access: (700/drwx------) Uid: ( 0/ root) Gid: ( 0/ root)"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.d/ conform with the CIS"
  fi

fi

# No flags specified
if [[ $flagUsed = "false" ]];
then
  if [[ $crontab_PermissionCheck != *"600/-rw-------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/crontab don't conform with the CIS Benchmark"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/crontab conform with the CIS Benchmark"
  fi

  if [[ $cronHourly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.hourly/ don't conform with the CIS Benchmark"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.hourly/ conform with the CIS Benchmark"
  fi

  if [[ $cronDaily_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.daily/ don't conform with the CIS Benchmark"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.daily/ conform with the CIS Benchmark"
  fi

  if [[ $cronWeekly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.weekly/ don't conform with the CIS Benchmark"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.weekly/ conform with the CIS Benchmark"
  fi

  if [[ $cronMonthly_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.monthly/ don't conform with the CIS Benchmark"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.monthly/ conform with the CIS Benchmark"
  fi

  if [[ $cronD_PermissionCheck != *"700/drwx------"* && $crontab_PermissionCheck != *"Uid: ( 0/ root) Gid: ( 0/ root)"* ]];
  then
    echo -e "${RED}[FAIL]${WHITE} The current set of permissions for /etc/cron.d/ don't conform with the CIS Benchmark"
  else
    echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/cron.d/ conform with the CIS"
  fi

fi

