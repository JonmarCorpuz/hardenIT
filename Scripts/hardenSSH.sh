#!/usr/bin/env bash 

# ==== STATIC VARIABLES =====================================================================
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"

set -o allexport
source ./Files/staticVariables.env
source ./Files/settings.conf
set +o allexport

# ==== HARDEN SSH ===========================================================================

# Ensure permissions on /etc/ssh/sshd_config are configured
if ls -ali /etc/ssh/sshd_config &> /dev/null;
then
   if { 
      l_output="" l_output2="" 
      perm_mask='0177' && maxperm="$( printf '%o' $(( 0777 & ~$perm_mask)) )" 
      SSHD_FILES_CHK() 
      { 
         while IFS=: read -r l_mode l_user l_group; do 
            l_out2="" 
            [ $(( $l_mode & $perm_mask )) -gt 0 ] && l_out2="$l_out2\n  - Is mode: \"$l_mode\" should be: \"$maxperm\" or more restrictive" 
            [ "$l_user" != "root" ] && l_out2="$l_out2\n  - Is owned by \"$l_user\" should be owned by \"root\"" 
            [ "$l_group" != "root" ] && l_out2="$l_out2\n  - Is group owned by \"$l_user\" should be group owned by \"root\"" 
            if [ -n "$l_out2" ]; then 
               l_output2="$l_output2\n - File: \"$l_file\":$l_out2" 
            else 
               l_output="$l_output\n - File: \"$l_file\":\n  - Correct: mode ($l_mode), owner ($l_user), and group owner ($l_group) configured" 
            fi 
         done < <(stat -Lc '%#a:%U:%G' "$l_file") 
      } 
      [ -e "/etc/ssh/sshd_config" ] && l_file="/etc/ssh/sshd_config" && 
   SSHD_FILES_CHK 
      while IFS= read -r -d $'\0' l_file; do 
         [ -e "$l_file" ] && SSHD_FILES_CHK 
      done < <(find -L /etc/ssh/sshd_config.d -type f  \( -perm /077 -o ! -user root -o ! -group root \) -print0 2>/dev/null) 
      if [ -z "$l_output2" ]; then 
         echo -e "\n- Audit Result:\n  *** PASS ***\n- * Correctly set * :\n$l_output\n" 
      else 
         echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n" 
         [ -n "$l_output" ] && echo -e " - * Correctly set * :\n$l_output\n" 
      fi 
   } | grep -q "PASS";
   then
      echo -e "${GREEN}[PASS]${WHITE} Permissions for /etc/ssh/sshd_config conform with the CIS Benchmark"  
   else
      echo -e "${RED}[FAIL]${WHITE} Permissions for /etc/ssh/sshd_config don't conform with the CIS Benchmark"
      if [[ $commitEnabled == "true" ]];
      then   
         echo -e "${YELLOW}[NOTICE]${WHITE} Modifying permissions for /etc/ssh/sshd_config to conform with the CIS Benchmark"
         { 
         sudo chmod u-x,og-rwx /etc/ssh/sshd_config 
         sudo chown root:root /etc/ssh/sshd_config 
         while IFS= read -r -d $'\0' l_file; do 
            if [ -e "$l_file" ]; then 
               sudo chmod u-x,og-rwx "$l_file" 
               sudo chown root:root "$l_file" 
            fi 
         done < <(find /etc/ssh/sshd_config.d -type f -print0 2>/dev/null) 
         }
         echo -e "${GREEN}[SUCCESS]${WHITE} Permissions for /etc/ssh/sshd_config now conform with the CIS Benchmark"
      fi

      if [[ $differenceEnabled == "true" ]];
      then 
         file="/etc/ssh/sshd_config"
         currentFilePermissions=$(stat -c '%a' "$file")
         currentFileOwner=$(stat -c '%U' $file)
         echo -e "* ${YELLOW}[INFO]${WHITE} Current permissions for /etc/ssh/sshd_config ---> Owner: $currentFileOwner && Permissions: $currentFilePermissions"
         echo -e "* ${YELLOW}[INFO]${WHITE} Expected permissions for /etc/ssh/sshd_config --> Owner: root && Permissions: 600 or more restrictive"
      fi 
   fi
else
   echo -e "${RED}[ERRPR]${WHITE} /etc/ssh/sshd_config was not found"
fi

# Ensure permissions on SSH private host key files are configured
   if {
      l_output="" l_output2="" 
      l_ssh_group_name="$(awk -F: '($1 ~ /^(ssh_keys|_?ssh)$/) {print $1}' /etc/group)" 
      FILE_CHK() 
      { 
         while IFS=: read -r l_file_mode l_file_owner l_file_group; do 
            l_out2="" 
            [ "l_file_group" = "$l_ssh_group_name" ] && l_pmask="0137" || l_pmask="0177" 
            l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )" 
            if [ $(( $l_file_mode & $l_pmask )) -gt 0 ]; then 
               l_out2="$l_out2\n  - Mode: \"$l_file_mode\" should be mode: \"$l_maxperm\" or more restrictive" 
            fi 
            if [ "$l_file_owner" != "root" ]; then 
               l_out2="$l_out2\n  - Owned by: \"$l_file_owner\" should be owned by \"root\"" 
            fi 
            if [[ ! "$l_file_group" =~ ($l_ssh_group_name|root) ]]; then 
               l_out2="$l_out2\n  - Owned by group \"$l_file_group\" should be group owned by: \"$l_ssh_group_name\" or \"root\"" 
            fi 
            if [ -n "$l_out2" ]; then 
               l_output2="$l_output2\n - File: \"$l_file\"$l_out2" 
            else 
               l_output="$l_output\n - File: \"$l_file\"\n  - Correct: mode: \"$l_file_mode\", owner: \"$l_file_owner\", and group owner: \"$l_file_group\" configured" 
            fi 
         done < <(stat -Lc '%#a:%U:%G' "$l_file") 
      } 
      while IFS= read -r -d $'\0' l_file; do  
         if ssh-keygen -lf &>/dev/null "$l_file"; then  
            file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?private\h+key\b' && FILE_CHK 
         fi 
      done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null) 
      if [ -z "$l_output2" ]; then 
         [ -z "$l_output" ] && l_output="\n  - No openSSH private keys found" 
         echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :$l_output" 
      else 
         echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :$l_output2\n" 
         [ -n "$l_output" ] && echo -e "\n - * Correctly configured * :\n$l_output\n" 
      fi 
   } | grep -q "PASS";
   then
      echo -e "${GREEN}[PASS]${WHITE} Permissions on SSH private host key files conform with the CIS Benchmark"
   else
      echo -e "${RED}[FAIL]${WHITE} Permissions on SSH private host key files don't conform with the CIS Benchmark"
      if [[ $commitEnabled == "true" ]];
      then 
         { 
            l_output="" l_output2="" 
            l_ssh_group_name="$(awk -F: '($1 ~ /^(ssh_keys|_?ssh)$/) {print $1}' /etc/group)" 
            FILE_ACCESS_FIX() 
            { 
               while IFS=: read -r l_file_mode l_file_owner l_file_group; do 
                  echo "File: \"$l_file\" mode: \"$l_file_mode\" owner \"$l_file_own\" group \"$l_file_group\"" 
                  l_out2="" 
                  [ "l_file_group" = "$l_ssh_group_name" ] && l_pmask="0137" || l_pmask="0177" 
                  l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )" 
                  if [ $(( $l_file_mode & $l_pmask )) -gt 0 ]; then 
                     l_out2="$l_out2\n  - Mode: \"$l_file_mode\" should be mode: \"$l_maxperm\" or more restrictive\n   - updating to mode: \:$l_maxperm\"" 
                     [ "l_file_group" = "$l_ssh_group_name" ] && chmod u-x,g-wx,o-rwx "$l_file" || chmod u-x,go-rwx 
                  fi 
                  if [ "$l_file_owner" != "root" ]; then 
                     l_out2="$l_out2\n  - Owned by: \"$l_file_owner\" should be owned by \"root\"\n   - Changing ownership to \"root\"" 
                     chown root "$l_file" 
                  fi 
                  if [[ ! "$l_file_group" =~ ($l_ssh_group_name|root) ]]; then 
                     [ -n "$l_ssh_group_name" ] && l_new_group="$l_ssh_group_name" || l_new_group="root" 
                     l_out2="$l_out2\n  - Owned by group \"$l_file_group\" should be group owned by: \"$l_ssh_group_name\" or \"root\"\n   - Changing group ownership to \"$l_new_group\"" 
                     chgrp "$l_new_group" "$l_file" 
                  fi 
                  if [ -n "$l_out2" ]; then 
                     l_output2="$l_output2\n - File: \"$l_file\"$l_out2" 
                  else 
                     l_output="$l_output\n - File: \"$l_file\"\n  - Correct: mode: \"$l_file_mode\", owner: \"$l_file_owner\", and group owner: \"$l_file_group\" configured" 
                  fi 
               done < <(stat -Lc '%#a:%U:%G' "$l_file") 
            } 
            while IFS= read -r -d $'\0' l_file; do  
               if ssh-keygen -lf &>/dev/null "$l_file"; then  
                  file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?private\h+key\b' && FILE_ACCESS_FIX 
               fi 
            done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null) 
            if [ -z "$l_output2" ]; then 
               echo -e "\n- No access changes required\n" 
            else 
               echo -e "\n- Remediation results:\n$l_output2\n" 
            fi 
         } 
      fi
      
      if [[ $differenceEnabled == "true" ]];
      then
         echo "tmp"
      fi  
   fi

# Ensure permissions on SSH public host key files are configured
if { 
   l_output="" l_output2="" 
   l_pmask="0133" && l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )" 
   FILE_CHK() 
   { 
      while IFS=: read -r l_file_mode l_file_owner l_file_group; do 
         l_out2="" 
         if [ $(( $l_file_mode & $l_pmask )) -gt 0 ]; then 
            l_out2="$l_out2\n  - Mode: \"$l_file_mode\" should be mode: \"$l_maxperm\" or more restrictive" 
         fi 
         if [ "$l_file_owner" != "root" ]; then 
            l_out2="$l_out2\n  - Owned by: \"$l_file_owner\" should be owned by \"root\"" 
         fi 
         if [ "$l_file_group" != "root" ]; then 
            l_out2="$l_out2\n  - Owned by group \"$l_file_group\" should be group owned by group: \"root\"" 
         fi 
         if [ -n "$l_out2" ]; then 
            l_output2="$l_output2\n - File: \"$l_file\"$l_out2" 
         else 
            l_output="$l_output\n - File: \"$l_file\"\n  - Correct: mode: \"$l_file_mode\", owner: \"$l_file_owner\", and group owner: \"$l_file_group\" configured" 
         fi 
      done < <(stat -Lc '%#a:%U:%G' "$l_file") 
   } 
   while IFS= read -r -d $'\0' l_file; do  
      if ssh-keygen -lf &>/dev/null "$l_file"; then  
         file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?public\h+key\b' && FILE_CHK 
      fi 
   done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null) 
   if [ -z "$l_output2" ]; then 
      [ -z "$l_output" ] && l_output="\n  - No openSSH public keys found" 
      echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :$l_output" 
   else 
      echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :$l_output2\n" 
      [ -n "$l_output" ] && echo -e "\n - * Correctly configured * :\n$l_output\n" 
   fi 
} | grep -q "tmp";
then
   echo -e "${GREEN}[PASS]${WHITE} Permissions on SSH public host key files conform with the CIS Benchmark"
else 
   { 
      l_output="" l_output2="" 
      l_pmask="0133" && l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )" 
      FILE_ACCESS_FIX() 
      { 
         while IFS=: read -r l_file_mode l_file_owner l_file_group; do 
            l_out2="" 
            if [ $(( $l_file_mode & $l_pmask )) -gt 0 ]; then 
               l_out2="$l_out2\n  - Mode: \"$l_file_mode\" should be mode: \"$l_maxperm\" or more restrictive\n   - updating to mode: \:$l_maxperm\"" 
               chmod u-x,go-wx 
            fi 
            if [ "$l_file_owner" != "root" ]; then 
               l_out2="$l_out2\n  - Owned by: \"$l_file_owner\" should be owned by \"root\"\n   - Changing ownership to \"root\"" 
               chown root "$l_file" 
            fi 
            if [ "$l_file_group" != "root" ]; then 
               l_out2="$l_out2\n  - Owned by group \"$l_file_group\" should be group owned by: \"root\"\n   - Changing group ownership to \"root\"" 
               chgrp root "$l_file" 
            fi 
            if [ -n "$l_out2" ]; then 
               l_output2="$l_output2\n - File: \"$l_file\"$l_out2" 
            else 
               l_output="$l_output\n - File: \"$l_file\"\n  - Correct: mode: \"$l_file_mode\", owner: \"$l_file_owner\", and group owner: \"$l_file_group\" configured" 
            fi 
         done < <(stat -Lc '%#a:%U:%G' "$l_file") 
      } 
      while IFS= read -r -d $'\0' l_file; do  
         if ssh-keygen -lf &>/dev/null "$l_file"; then  
            file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?public\h+key\b' && FILE_ACCESS_FIX 
         fi 
      done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null) 
      if [ -z "$l_output2" ]; then 
         echo -e "${GREEN}[PASS]${WHITE} Permissions on SSH public host key files conform with the CIS Benchmark (No access changes required)" 
      else 
         echo -e "\n- Remediation results:\n$l_output2\n" 
      fi 
   } 
fi 