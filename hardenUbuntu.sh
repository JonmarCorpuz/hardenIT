#!/bin/bash

# ==== STATIC VARIABLES =====================================================================
WHITE="\033[0m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
GREY="\033[38;5;254m"

# ==== FUNCTIONS ============================================================================
usageError() {
  echo "" && echo -e "${RED}[ERROR]${WHITE} Usage: ./hardenUbuntu.sh [--commit|--difference]" && echo ""
  exit 1
}

setVariables() {                       # Fonction pour charger les variables à partir des fichiers de configuration
  source ./Files/staticVariables.env   # Charge les variables d'environnement statiques
  source ./Files/settings.conf         # Charge les paramètres définis par l'utilisateur
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
setVariables
sudo chmod +x ./Scripts/*

# ==== MAIN BODY PT1 ========================================================================

echo ""

echo $commitEnabled
echo $differenceEnabled

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

# ==== MAIN BODY PT2 ========================================================================

echo -e "\n=================================================\n"

SETTINGS="settings-simple.com"
LOG_FILE="hardening.log"
declare -A config_params

#echo $commitEnabled
#echo $differenceEnabled

# Charger le fichier de configuration
loadConfig() {
  if [[ ! -f "./Files/settings-simple.conf" ]]; then
    echo -e "${RED}[ERROR]${WHITE} settings-simple.conf was not found"
    exit 1
  fi
  while IFS='=' read -r key value; do
    config_params["$key"]="$value"
  done < "./Files/settings-simple.conf"
}

checkParameters() {
  local key="$1"
  local expected_value="${config_params[$key]}"
  local current_value
  local label

  # Define user-friendly labels
  case $key in
    PASSWORD_MAX_DAYS) label="Max password age" ;;
    PASSWORD_MIN_DAYS) label="Min password age" ;;
    PASSWORD_WARN_AGE) label="Password warning age" ;;
    UMASK) label="Default umask" ;;
    SSH_PERMIT_ROOT_LOGIN) label="SSH root login" ;;
    SSH_PORT) label="SSH port" ;;
    SSH_PROTOCOL) label="SSH protocol" ;;
    SSH_MAX_AUTH_TRIES) label="SSH max auth tries" ;;
    SSH_LOG_LEVEL) label="SSH log level" ;;
    IP_FORWARD) label="IPv4 forwarding" ;;
    IPV6_REDIRECTS) label="IPv6 redirects" ;;
    ICMP_IGNORE_BROADCASTS) label="ICMP ignore broadcasts" ;;
    LOGIN_RETRIES) label="Login retries" ;;
    IPV4_REDIRECTS) label="IPv4 redirects" ;;
    UFW) label="Firewall (UFW)" ;;
    *) label="$key" ;;  # fallback
  esac

  # Fetch current values
  case $key in
    PASSWORD_MAX_DAYS) current_value=$(sudo su -c "grep -E '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}'") ;;
    PASSWORD_MIN_DAYS) current_value=$(sudo su -c "grep -E '^PASS_MIN_DAYS' /etc/login.defs | awk '{print $2}'") ;;
    PASSWORD_WARN_AGE) current_value=$(sudo su -c "grep -E '^PASS_WARN_AGE' /etc/login.defs | awk '{print $2}'") ;;
    UMASK) current_value=$(umask) ;;
    SSH_PERMIT_ROOT_LOGIN) current_value=$(sudo su -c "grep -E '^PermitRootLogin' /etc/ssh/sshd_config | awk '{print $2}'") ;;
    SSH_PORT) current_value=$(sudo su -c "grep -E '^Port' /etc/ssh/sshd_config | awk '{print $2}'") ;;
    SSH_PROTOCOL) current_value=$(sudo su -c "grep -E '^Protocol' /etc/ssh/sshd_config | awk '{print $2}'") ;;
    SSH_MAX_AUTH_TRIES) current_value=$(sudo su -c "grep -E '^MaxAuthTries' /etc/ssh/sshd_config | awk '{print $2}'") ;;
    SSH_LOG_LEVEL) current_value=$(sudo su -c "grep -E '^LogLevel' /etc/ssh/sshd_config | awk '{print $2}'") ;;
    IP_FORWARD) current_value=$(sudo su -c "sysctl net.ipv4.ip_forward | awk '{print $3}'") ;;
    IPV6_REDIRECTS) current_value=$(sudo su -c "sysctl net.ipv6.conf.all.accept_redirects | awk '{print $3}'") ;;
    ICMP_IGNORE_BROADCASTS) current_value=$(sudo su -c "sysctl net.ipv4.icmp_echo_ignore_broadcasts | awk '{print $3}'") ;;
    LOGIN_RETRIES) current_value=$(sudo su -c "grep -E '^LOGIN_RETRIES' /etc/login.defs | awk '{print $2}'") ;;
    IPV4_REDIRECTS) current_value=$(sudo su -c "sysctl net.ipv4.conf.all.accept_redirects | awk '{print $3}'") ;;
    UFW)
      if sudo ufw status | grep -q "Status: active"; then
        current_value="yes"
      else
        current_value="no"
      fi
      ;;
  esac

  # Format output to CLI only
  if [[ $differenceEnabled = "true" ]]; then
    if [[ -z "$current_value" ]]; then
      echo -e "${YELLOW}Current $label value${WHITE}: Not defined | Expected value: $expected_value"
    elif [[ "$current_value" != "$expected_value" ]]; then
      echo -e "${YELLOW}Current $label value${WHITE}: $current_value | Expected value: $expected_value"
    fi
  else
    echo -e "${YELLOW}Current $label value${WHITE}: $current_value | Expected value: $expected_value"
  fi
}

applyParameters() {
  local key="$1"
  local expected_value="${config_params[$key]}"

  case $key in
    PASSWORD_MAX_DAYS)
      sudo sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS $expected_value/" /etc/login.defs
      ;;
    PASSWORD_MIN_DAYS)
      sudo sed -i "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS $expected_value/" /etc/login.defs
      ;;
    PASSWORD_WARN_AGE)
      sudo sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE $expected_value/" /etc/login.defs
      ;;
    UMASK)
      sudo su -c 'echo "umask $expected_value" >> /etc/profile'
      ;;
    SSH_PERMIT_ROOT_LOGIN)
      sudo sed -i "s/^PermitRootLogin.*/PermitRootLogin $expected_value/" /etc/ssh/sshd_config
      ;;
    SSH_PORT)
      sudo sed -i "s/^Port.*/Port $expected_value/" /etc/ssh/sshd_config
      ;;
    SSH_PROTOCOL)
      sudo sed -i "s/^Protocol.*/Protocol $expected_value/" /etc/ssh/sshd_config
      ;;
    SSH_MAX_AUTH_TRIES)
      sudo sed -i "s/^MaxAuthTries.*/MaxAuthTries $expected_value/" /etc/ssh/sshd_config
      ;;
    SSH_LOG_LEVEL)
      sudo sed -i "s/^LogLevel.*/LogLevel $expected_value/" /etc/ssh/sshd_config
      ;;
    IP_FORWARD)
      sudo sysctl -w net.ipv4.ip_forward=$expected_value
      sudo su -c 'echo "net.ipv4.ip_forward = $expected_value" >> /etc/sysctl.conf'
      ;;
    IPV6_REDIRECTS)
      sudo sysctl -w net.ipv6.conf.all.accept_redirects=$expected_value
      sudo su -c 'echo "net.ipv6.conf.all.accept_redirects = $expected_value" >> /etc/sysctl.conf'
      ;;
    IPV4_REDIRECTS)
      sudo sysctl -w net.ipv4.conf.all.accept_redirects=$expected_value
      sudo su -c 'echo "net.ipv4.conf.all.accept_redirects = $expected_value" >> /etc/sysctl.conf'
      ;;
    ICMP_IGNORE_BROADCASTS)
      sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=$expected_value
      sudo su -c 'echo "net.ipv4.icmp_echo_ignore_broadcasts = $expected_value" >> /etc/sysctl.conf'
      ;;
    LOGIN_RETRIES)
      sudo sed -i "s/^LOGIN_RETRIES.*/LOGIN_RETRIES $expected_value/" /etc/login.defs
      ;;
    UFW)
      if [[ "$expected_value" == "yes" ]]; then
        sudo ufw --force enable
      else
        sudo ufw disable
      fi
      ;;
    *)
      echo "[WARN] Paramètre $key non pris en charge pour application automatique."
      ;;
  esac
}


loadConfig

# Loop through all config keys
for key in "${!config_params[@]}"; do

  checkParameters "$key"

  if [[ "$commitEnabled" == "true" ]]; then
    applyParameters "$key"
  fi
done

# Output based on differenceEnabled
if [[ "$differenceEnabled" == "true" ]]; then
  echo -e "\n${GREEN}[SUCCESS]${WHITE} Seules les différences ont été affichées."
else
  echo -e "\n${GREEN}[SUCCESS]${WHITE} Tous les paramètres ont été vérifiés."
fi

echo -e "\n${GREEN}[SUCCESS]${WHITE} Script executed with success"
sed -i "s/^commitEnabled=.*/commitEnabled=false/" ./Files/settings.conf
sed -i "s/^differenceEnabled=.*/differenceEnabled=false/" ./Files/settings.conf
sed -i "s/^flagUsed=.*/flagUsed=false/" ./Files/settings.conf
exit 0
