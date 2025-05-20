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



# ==== HARDEN APACHE SECURITY ===============================================================

# Ensure ServerTokens is set to Prod or ProductOnly
if grep -Pi '^\s*ServerTokens\s+(Prod|ProductOnly)' /etc/apache2/conf-available/security.conf -R &> /dev/null; then
   echo -e "${GREEN}[PASS]${WHITE} ServerTokens configuration in /etc/apache2/conf-available/sercurity.conf conforms with the CIS Benchmark"
else

    if cat /etc/apache2/conf-available/security.conf | grep "ServerTokens" &> /dev/null;
    then
        echo -e "${RED}[FAIL]${WHITE} ServerTokens configuration in /etc/apache2/conf-available/sercurity.conf doesn't conform with the CIS Benchmark"

        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Changing ServerTokens to be equal to Prod"
            sudo sed -i 's/^\s*ServerTokens\s\+OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf &> /dev/null
            echo -e "${GREEN}[SUCCESS]${WHITE} Successfully set ServerTokens to Prod"
        fi

        if [[ $differenceEnabled = "true" ]];
        then
            tmp=$(cat /etc/apache2/conf-available/security.conf | grep "ServerTokens" | sed 's/^/  /')
            echo -e "* ${GREY}[DEBUG]${WHITE} Current ServerTokens configuration\n${YELLOW}$tmp${WHITE}"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected ServerTokens configuration: ServerTokens Prod"
        fi

    else
        echo -e "${RED}[ERROR]${WHITE} ServerTokens is not present in /etc/apache2/conf-available/security.conf"

        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Adding the appropriate ServerTokens configuration to /etc/apache2/conf-available/sercurity.conf"
            sudo su -c "echo 'ServerTokens Prod' >> /etc/apache2/conf-available/security.conf" &> /dev/null
            echo -e "${GREEN}[SUCCESS]${WHITE} Successfully added ServerTokens configuration to /etc/apache2/conf-available/sercurity.conf"
        fi

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> /etc/apache2/conf-available/security.conf doens't contain the appropriate ServerTokens value"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> /etc/apache2/conf-available/security.conf should contain ServerTokens Prod"
        fi
    fi


fi

# ==== HARDEN APACHE ATTACK SURFACE =========================================================

# Ensure Options for the OS Root Directory are restricted
if ls -ali /etc/apache2/apache2.conf &> /dev/null;
then 

    # Check if <Directory /> block exists
    if grep -q -E '^\s*<Directory\s*/\s*>' /etc/apache2/apache2.conf; 
    then

        # Check if the Options directive is equal to None
        if awk '/<Directory \/>/,/<\/Directory>/ { if ($1=="Options" && $0 !~ /^\s*#/) if ($0 ~ /Options\s+None/) found=1 } END { exit !found }' /etc/apache2/apache2.conf; 
        then
            echo -e "${GREEN}[PASS]${WHITE} Options for the OS root directory conform with the CIS Benchmark" 
        else
            echo -e "${RED}[FAIL]${WHITE} Options for the OS root directory doesn't conform with the CIS Benchmark"

            if [[ $commitEnabled = "true" ]];
            then
                # If no Options line exists, insert it before </Directory>
                if ! sudo sed -n '/<Directory \/>/,/<\/Directory>/p' /etc/apache2/apache2.conf | grep -q 'Options' &> /dev/null; 
                then
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i '/<Directory \/>/,/<\/Directory>/ s|</Directory>|    Options None\n</Directory>|' "/etc/apache2/apache2.conf" &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                else 
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i "/<Directory \/>/,/<\/Directory>/ s/^\(\s*\)Options\s\+.*/\1Options None/" /etc/apache2/apache2.conf &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                fi
            fi

            if [[ $differenceEnabled = "true" ]];
            then 
                echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The Options directive in /etc/apache2/apache2.conf for the OS Root directory is not set to $tmp"
                echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The Options directive in /etc/apache2/apache2.conf for the OS Root directory should be set to None"
            fi
        fi 
    else
        echo -e "${RED}[ERROR]{$WHITE} No <Directory /> block was found in /etc/apache2/apache2.conf"
        
        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Adding the root directory block in /etc/apache2/apache2.conf"
            sudo su -c "echo -e '\n# Enforce minimal options at the root directory\n<Directory />\n    Options None\n    AllowOverride None\n    Require all denied\n</Directory>\n' >> /etc/apache2/apache2.conf"
            echo -e "${GREEN}[SUCCESS]${WHITE} The root directory block was successfully added in /etc/apache2/apache2.conf"
        fi 

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The root directory block is missing in /etc/apache2/apache2.conf"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The root directory needs to be configured with Options set to None in /etc/apache2/apache2.conf"
        fi 

    fi
else
    echo -e "${RED}[ERROR]${WHITE} /etc/apache2/apache2.conf was not found"
fi

# Ensure Options for the Web Root Directory are restricted
if ls -ali /etc/apache2/apache2.conf &> /dev/null;
then 

    # Check if <Directory /> block exists
    if grep '<Directory /var/www/html>' /etc/apache2/apache2.conf &> /dev/null; 
    then

        # Check if the Options directive is equal to None
        if awk '/<Directory \/var\/www\/html>/,/<\/Directory>/ { if ($1=="Options" && $0 !~ /^\s*#/) if ($0 ~ /Options\s+None/) found=1 } END { exit !found }' /etc/apache2/apache2.conf;        
        then 
            echo -e "${GREEN}[PASS]${WHITE} Options for the Web Root directory conform with the CIS Benchmark"
        else 
            echo -e "${RED}[FAIL]${WHITE} Options for the Web Root directory doesn't conform with the CIS Benchmark"

            if [[ $commitEnabled = "true" ]];
            then
                # If no Options line exists, insert it before </Directory>
                if ! sudo sed -n '/<Directory \/var\/www\/html>/,/<\/Directory>/p' /etc/apache2/apache2.conf | grep -q 'Options' &> /dev/null; 
                then
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i '/<Directory \/var\/www\/html>/,/<\/Directory>/ s|</Directory>|    Options None\n</Directory>|' /etc/apache2/apache2.conf &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                else 
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i '/<Directory \/var\/www\/html>/,/<\/Directory>/ s/^\(\s*\)Options\s\+.*/\1Options None/' /etc/apache2/apache2.conf &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                fi
            fi

            if [[ $differenceEnabled = "true" ]];
            then 
                echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The Options directive in /etc/apache2/apache2.conf the Web Root directory is not set to $tmp"
                echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The Options directive in /etc/apache2/apache2.conf the Web Root directory should be set to None"
            fi
        fi 
    else
        echo -e "${RED}[ERROR]${WHITE} No <Directory /var/www/html> block was found in /etc/apache2/apache2.conf"
        
        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Adding the root directory block in /etc/apache2/apache2.conf"
            sudo su -c "echo -e '\n<Directory /var/www/html>\n    Options None\n    AllowOverride None\n    Require all denied\n</Directory>\n' >> /etc/apache2/apache2.conf"
            echo -e "${GREEN}[SUCCESS]${WHITE} The root directory block was successfully added in /etc/apache2/apache2.conf"
        fi 

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The root directory block is missing in /etc/apache2/apache2.conf"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The root directory needs to be configured with Options set to None in /etc/apache2/apache2.conf"
        fi 

    fi
else
    echo -e "${RED}[ERROR]${WHITE} /etc/apache2/apache2.conf was not found"
fi

# ==== HARDEN APACHE PERMISSIONS ============================================================

# Ensure the Apache web server runs as a non-root user
if ls -ali /etc/apache2/apache2.conf &> /dev/null;
then 
    # Ensure the User and Group directives are present in the Apache configuration and not commented out
    if ! grep -E '^\s*(User|Group)\s+' /etc/apache2/apache2.conf &> /dev/null;
    then
        echo -e "${RED}[FAIL]${WHITE} The User, Group or both directives are commented in /etc/apache2/apache2.conf"

        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} "
            sudo sed -i 's/^\s*#\s*User\s\+\(.*\)/User \1/' /etc/apache2/apache2.conf
            sudo sed -i 's/^\s*#\s*Group\s\+\(.*\)/Group \1/' /etc/apache2/apache2.conf
            echo -e "${GREEN}[SUCCEESS]${WHITE}"
        fi

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} "
            echo -e "* ${GREY}[DEBUG]${WHITE} "
        fi

    else
        echo -e "${GREEN}[PASS]${WHITE} The User and Group directives are present in /etc/apache2/apache2.conf"
    fi

    # Ensure that Apache isn't running using the default user (www-data)    
    if grep -E '^\s*export\s+(APACHE_RUN_USER|APACHE_RUN_GROUP)' /etc/apache2/envvars | grep "www-data" &> /dev/null;
    then
        echo -e "${RED}[FAIL]${WHITE} The Apache web server is still using the default www-data user and group"

        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Creating a separate apache user and group"
            sudo groupadd -r apache
            sudo useradd apache -r -g apache -d /var/www -s /sbin/nologin
            echo -e "${GREEN}[SUCCESS]${WHITE} The apache user and group was created succesfully"
            echo -e "* ${YELLOW}[WARNING]${WHITE} Assigning the newly created apache user and group to the Apache web server"
            sudo sed -i -e 's/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=apache/' /etc/apache2/envvars
            sudo sed -i -e 's/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=apache/' /etc/apache2/envvars
            echo -e "${GREEN}[SUCCESS]${WHITE} The Apache web server is now successfully running under the newly created apache user and group"
        fi

        if [[ $differenceEnabled = "true" ]];
        then
            tmp1=$(grep -E '^export APACHE_RUN_USER=' /etc/apache2/envvars | sed 's/^.*=//')
            tmp2=$(grep -E '^export APACHE_RUN_GROUP=' /etc/apache2/envvars | sed 's/^.*=//')
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> Apache works under the $tmp1 user and $tmp2 group"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> Apache should work under the apacher user and apache group"
        fi

    else
        echo -e "${GREEN}[PASS]${WHITE} The Apache account UID is correct and conforms with the CIS Benchmark"
    fi

    # Ensure the Apache account UID is correct
    minimumUID=$(grep -E "^UID_MIN" /etc/login.defs | awk '{print $2}')
    userUID=$(id -u apache)
    if [[ "$userUID" -lt "$minimumUID" ]];
    then
        echo -e "${GREEN}[PASS]${WHITE} The non-root user running Apache has a UID ($userUID) that's lower than the minimum UID ($minimumUID)"
    else
        echo -e "${RED}[FAIL]${WHITE} The non-root user running Apache has a UID ($userUID) that's higher than the minimum UID ($minimumUID)"

        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Changing the apache user's UID to be lower than the minimum UID ($minimumUID)"
            newUID=$((minimumUID - 1))
            sudo usermod -u $newUID apache
            echo -e "${GREEN}[SUCCESS]${WHITE} The UID for apache was successfully modified to conform with the CIS Benchmark"
        fi

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The apache user has a UID of $userUID"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The apache user should have a UID lower than $minimumUID"
        fi 

    fi 

else
    echo -e "${RED}[ERROR]${WHITE} /etc/apache2/apache2.conf was not found"
fi

# Ensure the Apache user account has an invalid shell
if grep '^apache:' /etc/passwd | awk -F: '{exit ($7 == "/usr/sbin/nologin" || $7 == "/bin/false") ? 1 : 0}'; 
then
    echo -e "${GREEN}[PASS]${WHITE} The apache user is using an invalid shell"
else
    echo -e "${RED}[FAIL]${WHITE} The apache user is not using an invalid shell"

    if [[ $commitEnabled = "true" ]];
    then
        echo -e "* ${YELLOW}[WARNING]${WHITE} Changing the apache account to use the nologin shell"
        sudo chsh -s /sbin/nologin apache 
        echo -e "${GREEN}[SUCCESS]${WHITE} The apache account was successfully modified to use the nologin shell"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
        userShell=$(grep '^apache:' /etc/passwd | cut -d: -f7)
        echo -e "* ${GREY}[DEBUG]${WHITE} The apache user account is using $userShell shell"
        echo -e "* ${GREY}[DEBUG]${WHITE} The apache user account should using an invalid shell"
    fi
fi

# Ensure the Apache user account is locked
if [[ $(sudo passwd -S apache 2>/dev/null) =~ ^apache[[:space:]]+(L|LK) ]]; then
    echo -e "${GREEN}[PASS]${WHITE} The apache user account is locked"
else
    echo -e "${RED}[FAIL]${WHITE} The apache user account is not locked"

    if [[ $commitEnabled = "true" ]];
    then
        echo -e "* ${YELLOW}[WARNING]${WHITE} Locking the apache user account"
        sudo passwd -l apache &> /dev/null
        echo -e "${GREEN}[SUCCESS]${WHITE} Successfully locked the apache user account"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
        echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration --->"
        echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration -->"
    fi 
fi

# Ensure Apache directories and files are owned by root
if ! sudo find /etc/apache2 ! -user root -exec ls -l {} + | grep -q "total 0"; then
    echo -e "${GREEN}[PASS]${WHITE} All Apache directories and files are owned by root"
else 
    echo -e "${RED}[FAIL]${WHITE} Not all Apache directories and files are owned by root"

    if [[ $commitEnabled = "true" ]];
    then
        echo -e "* ${YELLOW}[WARNING]${WHITE}"
        sudo chown -R root /etc/apache2 &> /dev/null
        echo -e "${GREEN}[SUCCESS]${WHITE}"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
        nonRootOwned=$(sudo find /etc/apache2 ! -user root -exec ls -l {} +)
        echo -e "* ${GREY}[DEBUG]${WHITE} Current files not owned by root:\n  $nonRootOwned"
        echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration: All files should be owned by root"
    fi

fi

# Ensure the group is set correctly on Apache directories and files
if ! sudo find /etc/apache2 -type d ! -user root -exec ls -ld {} + | grep -q "total 0"; 
then
    echo -e "${GREEN}[PASS]${WHITE} All files and directories in /etc/apache2 are group-owned by root"
else
    echo -e "${RED}[FAIL]${WHITE} All files and directories in /etc/apache2 are not group-owned by root"

    if [[ $commitEnabled = "true" ]];
    then
        echo -e "* ${YELLOW}[WARNING]${WHITE}"
        sudo chgrp -R root /etc/apache2 &> /dev/null
        echo -e "${GREEN}[SUCCESS]${WHITE}"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
        nonRootOwned=$(sudo find /etc/apache2 ! -user root -exec ls -ld {} +)
        echo -e "* ${GREY}[DEBUG]${WHITE} Current files not group-owned by root:\n  $nonRootOwned"
        echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration: All files should be group-owned by root"
    fi

fi

# Ensure other write access on Apache directories and files are restricted
if ! sudo find -L /etc/apache2 \! -type l -perm /o=w | grep -q .; 
then
    echo -e "${GREEN}[PASS]${WHITE} Write access for others on Apache directories and files conforms with the CIS Benchmark"
else 
    echo -e "${RED}[FAIL]${WHITE} Write access for others on Apache directories and files does not conform with the CIS Benchmark"

    if [[ $commitEnabled = "true" ]];
    then
        echo -e "* ${YELLOW}[WARNING]${WHITE} Restricting Apache directories from others"
        sudo chmod -R o-w /etc/apache2 &> /dev/null
        echo -e "* ${GREEN}[SUCCESS]${WHITE} Successfully restricted Apache directories from others"

    fi

    if [[ $differenceEnabled = "true" ]];
    then
        echo -e "* ${GREY}[DEBUG]${WHITE}"
        echo -e "* ${GREY}[DEBUG]${WHITE}"
    fi

fi

# Ensure the Core Dump directory is secured
coreDumpDirectory=$(grep -Ri "CoreDumpDirectory" /etc/apache2/ | awk '{print $2}' | head -n 1)
documentRootDirectory=$(grep -Ri "DocumentRoot" /etc/apache2/sites-enabled/ | awk '{print $2}' | head -n 1)

if [[ -n "$coreDumpDirectory" && -n "$documentRootDirectory" && "$coreDumpDirectory" == "$documentRootDirectory"* ]]; then
  echo -e "${RED}[FAIL]${WHITE} The CoreDumpDirectory ($coreDumpDirectory) is within the DocumentRoot ($documentRootDirectory)"
else
  echo -e "${GREEN}[PASS]${WHITE} THe CoreDumpDirectory is not inside the DocumentRoot"
fi

if sudo find /etc/apache2 -perm /007 -exec ls -ld {} + | grep -q . &> /dev/null;
then
  echo -e "${GREEN}[PASS]${WHITE} All Apache directories and files don't have read-write-search access permissions for other users"
else 
  echo -e "${GREEN}[PASS]${WHITE} Some Apache directories and files have read-write-search access permissions for other users"

  if [[ $commitEnabled = "true" ]];
  then
    echo -e "* ${YELLOW}[WARNING]${WHITE} Modifying permissions for all Apache directories and files so that others don't have read-write-search permissions"
    sudo chmod -R o-rw /etc/apache2/
    echo -e "${GREEN}[SUCCESS]${WHITE} Modifications successfull"
  fi

  if [[ $differenceEnabled = "true" ]];
  then
    echo -e "* ${GREY}[DEBUG]${WHITE} "
    echo -e "* ${GREY}[DEBUG]${WHITE}"
  fi 

fi

# Ensure group write access for the Apache directories and files is properly restricted
if sudo find /etc/apache2 \( -type f -o -type d \) -perm /020 -exec ls -ld {} + | grep -q . &> /dev/null;
then
  echo -e "${GREEN}[PASS]${WHITE} Group write access for the Apache directories and files conforms with the CIS Benchmark"
else
  echo -e "${RED}[FAIL]${WHITE} Group write access for the Apache directories and files desn't conform with the CIS Benchmark"

  if [[ $commitEnabled = "true" ]];
  then
    echo -e "* ${YELLOW}[WARNING]${WHITE} "
    sudo find /etc/apache2 \( -type f -o -type d \) -perm /020 -exec chmod g-w {} + &> /dev/null
    echo -e "* ${GREEN}[SUCCESS]${WHITE} "
  fi

  if [[ $differenceEnabled = "true" ]];
  then
    echo -e "* ${GREY}[DEBUG]${WHITE} "
    echo -e "* ${GREY}[DEBUG]${WHITE} "

  fi 

fi 

# Ensure group write access for the document root directories and files is properly restricted
tmp=$(grep -E '^export APACHE_RUN_GROUP=' /etc/apache2/envvars | cut -d= -f2)

if sudo find /var/www/html \( -type f -o -type d \) -group "$tmp" -perm /020 -exec ls -ld {} + | grep -q . &> /dev/null;
then
  echo -e "${GREEN}[PASS]${WHITE} Group write access for the Document Root directories and files conforms with the CIS Benchmark"
else 
  echo -e "${RED}[FAIL]${WHITE} Group write access for the Document Root directories and files does not conform with the CIS Benchmark"

  if [[ $commitEnabled = "true" ]];
  then
    echo -e "* ${YELLOW}[WARNING]${WHITE} Removing group write access from the Document Root directories and files"
    # Remove group write from files
    sudo find /var/www/html -type f -group apache -perm /020 -exec chmod g-w {} + &> /dev/null

    # Remove group write from directories
    sudo find /var/www/html -type d -group apache -perm /020 -exec chmod g-w {} + &> /dev/null

    echo -e "* ${GRENN}[SUCCESS]${WHITE} Successfully removed group write access from the Document Root directories and files"
  fi

  if [[ $differenceEnabled = "true" ]];
  then
    echo -e "* ${GREY}[DEBUG]${WHITE} "
    echo -e "* ${GREY}[DEBUG]${WHITE} "
  fi

fi

# ==== HARDEN APACHE ACCESS CONTROL =========================================================

# Ensure Access to OS Root Directory is denied by default
if ls -ali /etc/apache2/apache2.conf &> /dev/null;
then 

    # Check if <Directory /> block exists
    if grep -q -E '^\s*<Directory\s*/\s*>' /etc/apache2/apache2.conf; 
    then

        # Check if the Options directive is equal to None
        if awk '/<Directory \/>/,/<\/Directory>/ { if ($1=="Options" && $0 !~ /^\s*#/) if ($0 ~ /Options\s+None/) found=1 } END { exit !found }' /etc/apache2/apache2.conf; 
        then
            echo -e "${GREEN}[PASS]${WHITE} Require for the OS root directory conform with the CIS Benchmark" 
        else
            echo -e "${RED}[FAIL]${WHITE} Require for the OS root directory doesn't conform with the CIS Benchmark"

            if [[ $commitEnabled = "true" ]];
            then
                # If no Options line exists, insert it before </Directory>
                if ! sudo sed -n '/<Directory \/>/,/<\/Directory>/p' /etc/apache2/apache2.conf | grep -q 'Require' &> /dev/null; 
                then
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i '/<Directory \/>/,/<\/Directory>/ s|</Directory>|    Require all denied\n</Directory>|' "/etc/apache2/apache2.conf" &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                else 
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i "/<Directory \/>/,/<\/Directory>/ s/^\(\s*\)Require\s\+.*/\1Require all denied/" /etc/apache2/apache2.conf &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                fi
            fi

            if [[ $differenceEnabled = "true" ]];
            then 
                echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The Require directive in /etc/apache2/apache2.conf for the OS Root directory is not set to $tmp"
                echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The Require directive in /etc/apache2/apache2.conf for the OS Root directory should be set to all denied"
            fi
        fi 
    else
        echo -e "${RED}[ERROR]{$WHITE} No <Directory /> block was found in /etc/apache2/apache2.conf"
        
        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Adding the root directory block in /etc/apache2/apache2.conf"
            sudo su -c "echo -e '\n<Directory />\n    Options None\n    AllowOverride None\n    Require all denied\n</Directory>\n' >> /etc/apache2/apache2.conf"
            echo -e "${GREEN}[SUCCESS]${WHITE} The root directory block was successfully added in /etc/apache2/apache2.conf"
        fi 

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The root directory block is missing in /etc/apache2/apache2.conf"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The root directory needs to be configured with Options set to None in /etc/apache2/apache2.conf"
        fi 

    fi
else
    echo -e "${RED}[ERROR]${WHITE} /etc/apache2/apache2.conf was not found"
fi

# Ensure OverRide is disabled for the OS Root Directory
if ls -ali /etc/apache2/apache2.conf &> /dev/null;
then 

    # Check if <Directory /> block exists
    if grep -q -E '^\s*<Directory\s*/\s*>' /etc/apache2/apache2.conf; 
    then

        # Check if the Options directive is equal to None
        if awk '/<Directory \/>/,/<\/Directory>/ { if ($1=="Options" && $0 !~ /^\s*#/) if ($0 ~ /Options\s+None/) found=1 } END { exit !found }' /etc/apache2/apache2.conf; 
        then
            echo -e "${GREEN}[PASS]${WHITE} AllowOverride for the OS root directory conform with the CIS Benchmark" 
        else
            echo -e "${RED}[FAIL]${WHITE} AllowOverride for the OS root directory doesn't conform with the CIS Benchmark"

            if [[ $commitEnabled = "true" ]];
            then
                # If no Options line exists, insert it before </Directory>
                if ! sudo sed -n '/<Directory \/>/,/<\/Directory>/p' /etc/apache2/apache2.conf | grep -q 'AllowOverride' &> /dev/null; 
                then
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i '/<Directory \/>/,/<\/Directory>/ s|</Directory>|    AllowOverride None\n</Directory>|' "/etc/apache2/apache2.conf" &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                else 
                    echo -e "* ${YELLOW}[WARNING]${WHITE}"
                    sudo sed -i "/<Directory \/>/,/<\/Directory>/ s/^\(\s*\)AllowOverride\s\+.*/\AllowOverride None/" /etc/apache2/apache2.conf &> /dev/null
                    echo -e "${GREEN}[SUCCESS]${WHITE}"
                fi
            fi

            if [[ $differenceEnabled = "true" ]];
            then 
                echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The AllowOverride directive in /etc/apache2/apache2.conf for the OS Root directory is not set to $tmp"
                echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The AllowOverride directive in /etc/apache2/apache2.conf for the OS Root directory should be set to None"
            fi
        fi 
    else
        echo -e "${RED}[ERROR]{$WHITE} No <Directory /> block was found in /etc/apache2/apache2.conf"
        
        if [[ $commitEnabled = "true" ]];
        then
            echo -e "* ${YELLOW}[WARNING]${WHITE} Adding the root directory block in /etc/apache2/apache2.conf"
            sudo su -c "echo -e '\n<Directory />\n    Options None\n    AllowOverride None\n    Require all denied\n</Directory>\n' >> /etc/apache2/apache2.conf"
            echo -e "${GREEN}[SUCCESS]${WHITE} The root directory block was successfully added in /etc/apache2/apache2.conf"
        fi 

        if [[ $differenceEnabled = "true" ]];
        then
            echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> The root directory block is missing in /etc/apache2/apache2.conf"
            echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> The root directory needs to be configured with Options set to None in /etc/apache2/apache2.conf"
        fi 

    fi
else
    echo -e "${RED}[ERROR]${WHITE} /etc/apache2/apache2.conf was not found"
fi

# ==== HARDEN APACHE OPERATIONS =============================================================

# Ensure the error log filename and severity are configured correctly
if grep -Ri '^\s*LogLevel' /etc/apache2/apache2.conf &> /dev/null;
then
    echo -e "${RED}[FAIL]${WHITE}"

    if [[ $commitEnabled = "true" ]];
    then
        echo -e "* ${YELLOW}[WARNING]${WHITE} Modifying the LogLevel to info"
        sudo sed -i 's/^\s*LogLevel\s\+warn/LogLevel info/' /etc/apache2/apache2.conf
        echo -e "${GREEN}[SUCCESS]${WHITE} LogLevel was successfully changed to info"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
        tmp=$(grep -Ri '^\s*LogLevel' /etc/apache2/apache2.conf)
        echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> $tmp"
        echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> LogLevel info"
    fi
else
    echo -e "${RED}[ERROR]${WHITE} No LogLevel directive found in /etc/apache2/apache2.conf"

    if [[ $commitEnabled = "true" ]];
    then
        echo -e "* ${YELLOW}[WARNING]${WHITE} Adding the proper LogLevel in /etc/apache2/apache2.conf"
        sudo su -c "echo 'LogLevel info' >> /etc/apache2/apache2.conf"
        echo -e "${GREEN}[SUCCESS]${WHITE} Successfully added the proper LogLevel in /etc/apache/apache2.conf"
    fi

    if [[ $differenceEnabled = "true" ]];
    then
        tmp=$(grep -Ri '^\s*LogLevel' /etc/apache2/apache2.conf)
        echo -e "* ${GREY}[DEBUG]${WHITE} Current configuration ---> LogLevel is not present in /etc/apache2/apache2.conf"
        echo -e "* ${GREY}[DEBUG]${WHITE} Expected configuration --> LogLevel info should be present in /etc/apache2/apache2.conf"
    fi

fi 