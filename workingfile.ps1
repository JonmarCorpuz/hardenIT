# Paramètres d'entrée pour le script
param(
    # Le paramètre $commit permet de confirmer et d'appliquer les changements
    [switch]$commit, 
    
    # Le paramètre $difference permet de vérifier et afficher les différences sans apporter de modifications
    [switch]$difference
)

# Définition du chemin vers le fichier de configuration JSON
$configPath = "./config.json"

# Lecture du fichier de configuration et conversion du contenu en objet JSON
$config = Get-Content $configPath | ConvertFrom-Json

# Fonction pour récupérer la valeur actuelle d'un paramètre système (Pour sans option et -difference)
function Get-CurrentValue($settingName) {
    switch ($settingName) {
        "EnableFirewall" { 
            return (Get-NetFirewallProfile -Profile Domain,Public,Private).Enabled 
        }
        "PasswordComplexity" { 
            return (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters").RequireStrongKey 
        }
        "Geolocation" { 
            return (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc").Start 
        }
        "AccountLockoutDuration" { 
            return (Get-ItemPropertyValue -Path "HKLM:\System\CurrentControlSet\Services\RemoteAccess\Parameters\AccountLockout" -Name "ResetTime (mins)") 
        }
        "LanmanServer" { 
            return (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer").Start 
        }
        "MaximumPasswordAge" { 
            return (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters").MaximumPasswordAge 
        }
        "AuditPolicySuccess" { 
            #return ((auditpol /get /subcategory:"Logon" | Where-Object { $_ -match "Logon" }))

            $tmp = auditpol /get /subcategory:"Logon" | Where-Object { $_ -match "Logon" }
            if ($tmp | Where-Object { $_ -match "Success" }) {
                return "enable"
            } else {
                return "disable"
            }
        }
        "AuditPolicyFailure" { 
            #return ((auditpol /get /subcategory:"Logoff" | Where-Object { $_ -match "Logoff" })) 
            $tmp = auditpol /get /subcategory:"Logon" | Where-Object { $_ -match "Logon" }
            if ($tmp | Where-Object { $_ -match "Failure" }) {
                return "enable"
            } else {
                return "disable"
            }
        }
        "DisableAutoplay" { 
            return (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer").NoDriveTypeAutoRun -eq 255 
        }
        "DisableRemoteDesktop" { 
            return (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections -eq 1 
        }
        "EnableUAC" { 
            return (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").EnableLUA -eq 1 
        }
        "DisableAnonymousShareAccess" { 
            return (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa").RestrictAnonymous -eq 1 
        }
        "IPv6" { 
            return (Get-NetAdapterBinding -ComponentID ms_tcpip6).Enabled 
        }
        "RemoteRegistry" { 
            return (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteRegistry").Start 
        }
        "SSDPDiscovery" { 
            return (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SSDPSRV").Start 
        }
    }
}

# Fonction pour appliquer les paramètres de sécurité à partir de la configuration (-commit)
function Set-SecuritySetting($settingName, $value) {
    switch ($settingName) {
        "EnableFirewall" { 
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled $value 
        }
        "PasswordComplexity" { 
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters" -Name "RequireStrongKey" -Value $value 
        }
        "Geolocation" { 
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc" -Name "Start" -Value $value 
        }
        "AccountLockoutDuration" { 
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\RemoteAccess\Parameters\AccountLockout" -Name "ResetTime (mins)" -Value $value 
        }
        "LanmanServer" { 
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer" -Name "Start" -Value $value 
        }
        "MaximumPasswordAge" { 
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters" -Name "MaximumPasswordAge" -Value $value 
        }
        "AuditPolicySuccess" { 
            auditpol /set /category:"Logon/Logoff" /success:$value 
        }
        "AuditPolicyFailure" { 
            auditpol /set /category:"Logon/Logoff" /failure:$value 
        }
        "DisableAutoplay" { 
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 
        }
        "DisableRemoteDesktop" { 
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1 
        }
        "EnableUAC" { 
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 
        }
        "DisableAnonymousShareAccess" { 
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Value 1 
        }
        "IPv6" { 
            Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 
        }
        "RemoteRegistry" { 
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteRegistry" -Name "Start" -Value $value 
        }
        "SSDPDiscovery" { 
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SSDPSRV" -Name "Start" -Value $value 
        }
    }
}

# Boucle pour parcourir tous les paramètres définis dans la configuration JSON pour trouver les differences (-difference)
foreach ($setting in $config.PSObject.Properties) {
    $settingName = $setting.Name
    $configValue = $setting.Value
    $currentValue = Get-CurrentValue $settingName
    
    # Vérifie s'il y a une différence entre la valeur actuelle et la valeur de la configuration
    if ($difference -and ($currentValue -ne $configValue)) {
        Write-Host "Différence trouvée pour $settingName : Actuel = $currentValue, Configuré = $configValue" -ForegroundColor Yellow
    }
    
    # Si le paramètre "difference" n'est pas passé, affiche la différence sans appliquer de changement
    if (-not $difference) {
        Write-Host "$settingName : Actuel = $currentValue, Configuré = $configValue" -ForegroundColor Cyan
    }
    
    # Si le paramètre "commit" est passé, applique les changements
    if ($commit -and ($currentValue -ne $configValue)) {
        Set-SecuritySetting $settingName $configValue
        Write-Host "Paramètre $settingName mis à jour" -ForegroundColor Green
    }
}

