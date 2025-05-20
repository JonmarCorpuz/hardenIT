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

# ==== HARDEN PROCESSES =====================================================================

# Ensure address space layout randomization is enabled
if {
    l_output="" l_output2=""
    a_parlist=(kernel.randomize_va_space=2)
    l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
    kernel_parameter_chk()
    {
        l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" # Check running configuration
        if [ "$l_krp" = "$l_kpvalue" ]; then
            l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
        else
            l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
        fi
        unset A_out; declare -A A_out # Check durable setting (files)
        while read -r l_out; do
            if [ -n "$l_out" ]; then
                if [[ $l_out =~ ^\s*# ]]; then
                l_file="${l_out//# /}"
                else
                l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_file")
                fi
            fi
        done < <(/usr/lib/systemd/systemd-sysctl --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')
        if [ -n "$l_ufwscf" ]; then # Account for systems with UFW (Not covered by systemd-sysctl --cat-config)
            l_kpar="$(grep -Po "^\h*$l_kpname\b" "$l_ufwscf" | xargs)"
            l_kpar="${l_kpar//\//.}"
            [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
        fi
        if (( ${#A_out[@]} > 0 )); then # Assess output from files and generate output
            while IFS="=" read -r l_fkpname l_fkpvalue; do
                l_fkpname="${l_fkpname// /}"; l_fkpvalue="${l_fkpvalue// /}"
                if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
                l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\"\n"
                else
                l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_kpvalue\"\n" 
                fi
            done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
        else
            l_output2="$l_output2\n - \"$l_kpname\" is not set in an included file\n   ** Note: \"$l_kpname\" May be set in a file that's ignored by load procedure **\n" 
        fi
    }
    while IFS="=" read -r l_kpname l_kpvalue; do # Assess and check parameters 
        l_kpname="${l_kpname// /}"; l_kpvalue="${l_kpvalue// /}"
        if ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && grep -q '^net.ipv6.' <<< "$l_kpname"; then 
            l_output="$l_output\n - IPv6 is disabled on the system, \"$l_kpname\" is not applicable" 
        else
            kernel_parameter_chk
        fi
    done < <(printf '%s\n' "${a_parlist[@]}")
    if [ -z "$l_output2" ]; then # Provide output from checks
        echo -e "\n- Audit Result:\n  ** PASS **\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n  ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
        [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
    fi
} | grep -q "FAIL";
then
  if file /etc/sysctl.conf &> /dev/null;
  then 
    echo -e "${RED}[FAIL]${WHITE} Process address space layout randomization conforms with the CIS Benchmark"
    if [[ $commitEnabled = "true" ]];
    then
      echo -e "* ${YELLOW}[WARNING]${WHITE} Modifying the process address space layout randomization to make it conform with the CIS Benchmark"
      sudo su -c 'printf "%s\n" "kernel.randomize_va_space = 2" >> /etc/sysctl.conf'
      sudo sysctl -w kernel.randomize_va_space=2
      echo -e "${GREEN}[SUCCESS]${WHITE} Process address space layout randomization now conforms with the CIS Benchmark"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
      echo -e "* ${GREY}[DEBUG]${WHITE} Audit Result --> FAIL"
      echo -e "* ${GREY}[DEBUG]${WHITE} Audit Result --> PASS"
      echo -e "${YELLOW}[WARNING]${WHITE} Please set kernel.randomize_va_space to 2 in /etc/sysctl.conf"
    fi
  else 
    echo -e "${RED}[ERROR]${WHITE} /etc/sysctl.conf was not found"
  fi 
else
  echo -e "${GREEN}[PASS]${WHITE} Process address space layout randomization conforms with the CIS Benchmark"
fi

# Ensure core dumps are restricted
if {
   l_output="" l_output2=""
   a_parlist=("fs.suid_dumpable=0")
   l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
   kernel_parameter_chk()
   {
      l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" # Check running configuration
      if [ "$l_krp" = "$l_kpvalue" ]; 
      then
         l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration" 
      else
         l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\"" 
      fi
      unset A_out; declare -A A_out # Check durable setting (files)
      while read -r l_out; 
      do
         if [ -n "$l_out" ]; 
         then
            if [[ $l_out =~ ^\s*# ]]; 
            then
               l_file="${l_out//# /}"
            else
               l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
               [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_file")
            fi
         fi
      done < <(/usr/lib/systemd/systemd-sysctl --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')
      if [ -n "$l_ufwscf" ]; 
      then # Account for systems with UFW (Not covered by systemd-sysctl --cat-config)
         l_kpar="$(grep -Po "^\h*$l_kpname\b" "$l_ufwscf" | xargs)"
         l_kpar="${l_kpar//\//.}"
         [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
      fi
      if (( ${#A_out[@]} > 0 )); 
      then # Assess output from files and generate output
         while IFS="=" read -r l_fkpname l_fkpvalue; 
         do
            l_fkpname="${l_fkpname// /}"; l_fkpvalue="${l_fkpvalue// /}"
            if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
               l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\"\n"
            else
               l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_kpvalue\"\n"
            fi
         done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
      else
         l_output2="$l_output2\n - \"$l_kpname\" is not set in an included file\n   ** Note: \"$l_kpname\" May be set in a file that's ignored by load procedure **\n"
      fi
   }
   while IFS="=" read -r l_kpname l_kpvalue; 
   do # Assess and check parameters
      l_kpname="${l_kpname// /}"; l_kpvalue="${l_kpvalue// /}"
      if ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && grep -q '^net.ipv6.' <<< "$l_kpname"; then
         l_output="$l_output\n - IPv6 is disabled on the system, \"$l_kpname\" is not applicable"
      else
         kernel_parameter_chk
      fi
   done < <(printf '%s\n' "${a_parlist[@]}")
   if [ -z "$l_output2" ]; 
   then # Provide output from checks
      echo -e "\n- Audit Result:\n  ** PASS **\n$l_output\n"
   else
      echo -e "\n- Audit Result:\n  ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
      [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
   fi
} | grep -q "FAIL";
then
  if file /etc/security/limits.conf &> /dev/null;
  then
    echo -e "${RED}[FAIL]${WHITE} Core dumps restrictions dont't conform with the CIS Benchmark"
    if [[ $commitEnabled = true ]];
    then
      echo -e "* ${YELLOW}[WARNING]${WHITE} Modifying core dump restrictions to conform with the CIS Benchmark"
      sudo su -c 'printf "%s\n" "* hard core 0" >> /etc/security/limits.conf'
      sudo sysctl -w fs.suid_dumpable=0 
      sudo sed -i 's/^fs.suid_dumpable=.*/fs.suid_dumpable=0/' /usr/lib/sysctl.d/50-coredump.conf
      if file /etc/systemd/coredump.conf &> /dev/null;
      then 
        sudo su -c 'echo "Storage=none" >> /etc/systemd/coredump.conf'
        sudo su -c 'echo "ProcessSizeMax=0" >> /etc/systemd/coredump.conf'
      fi 
    fi

    if [[ $differenceEnabled = true ]];
    then
      echo -e "* ${GREY}[DEBUG]${WHITE} Current audit result ---> FAIL"
      echo -e "* ${GREY}[DEBUG]${WHITE} Expected audit result --> PASS"
    fi
  else 
    echo -e "${RED}[ERROR]${WHITE} /etc/security/limits.conf was not found"
  fi  
else
  echo -e "${GREEN}[PASS]${WHITE} Core dumps restrictions conform with the CIS Benchmark"
fi

# Ensure prelink is not installed
if ! dpkg-query -s prelink &>/dev/null;
then
  echo -e "${GREEN}[PASS]${WHITE} Prelink isn't installed"
else
  echo -e "${RED}[FAIL]${WHITE} Prelink shouldn't be installed according to the CIS Benchmark"

  if [[ $commitEnabled = "true" ]];
  then
    echo -e "${YELLOW}[WARNING]${WHITE} Uninstalling prelink as per CIS Benchmark"
    sudo apt -y purge prelink &> /dev/null
    echo -e "${GREEN}[SUCCESS]${WHITE} Prelink was successfully uninstalled"
  fi

  if [[ $differenceEnabled = "true" ]];
  then
    echo -e "* ${GREY}[DEBUG]${WHITE} Current value ---> prelink is currently installed"
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected value --> prelink shouldn't be installed"
  fi
fi

if ! systemctl is-active apport.service | grep '^active';
then
  echo -e "${GREEN}[PASS]${WHITE} Apport Error Reporting Service is not enabled"
else
  echo -e "${RED}[FAIL]${WHITE} Apport Error Reporting Service is currently active"
  if [[ $commitEnabled = "true" ]];
  then
    echo -e "${YELLOW}[WARNING]${WHITE} Uninstalling the Apport Error Reporting Service to confirm with CIS Benchmark"
    sudo apt -y purge apport
  fi

  if [[ $differenceEnabled = "true" ]];
  then
    echo -e "* ${GREY}[DEBUG]${WHITE} Current value ---> apport is installed"
    echo -e "* ${GREY}[DEBUG]${WHITE} Expected value --> apport shouldn't be installed"
  fi
fi
