# Table des Matières

1. [Étapes d'Installation](#étapes-dinstallation)
2. [Utilisation du Script](#utilisation-du-script)
3. [Paramètres de Sécurité et de Configuration Système](#paramètres-de-sécurité-et-de-configuration-système)


# Guide d'Installation et d'Utilisation du Script de Configuration de Sécurité

## Étapes d'installation

1. **Créer un nouveau dossier** sur votre système pour stocker les fichiers du script, par exemple "SecurityConfig".
   
2. **Dans ce dossier, créez deux fichiers** :
   - `config.json` : Ce fichier contiendra la configuration JSON fournie.
   - `workingfile.ps1` : Ce fichier contiendra le script PowerShell.

3. **Copiez le contenu JSON** dans le fichier `config.json`.

4. **Copiez le script PowerShell** dans le fichier `workingfile.ps1`.

---

## Utilisation du script

1. **Ouvrez PowerShell en tant qu'administrateur**.  
   - Pour ce faire, recherchez "PowerShell" dans le menu Démarrer, puis cliquez avec le bouton droit sur "Windows PowerShell" et sélectionnez "Exécuter en tant qu'administrateur".

2. **Naviguez vers le dossier contenant les fichiers** :
   
   ```powershell
   cd C:\chemin\vers\SecurityConfig
   ```

## Option d'éxecution du script

Vous avez plusieurs options pour exécuter le script :

### a. Vérifier les différences sans appliquer de changements :

Pour voir quelles différences existent entre l'état actuel et la configuration souhaitée, sans appliquer de modifications :

```powershell
.\workingfile.ps1 -difference
```

### b. Afficher l'état actuel et la configuration souhaitée :

Pour afficher l'état actuel de la configuration et la configuration souhaitée (sans effectuer de changements) :
```powershell
.\workingfile.ps1
```

### c. Appliquer les changements de configuration :

Pour appliquer les changements définis dans le fichier de configuration, utilisez l'option -commit :
```powershell
.\workingfile.ps1 -commit
```


# Paramètres de Sécurité et de Configuration Système

## 1. EnableFirewall
- **Description** : Active ou désactive le pare-feu de Windows.
- **Valeurs possibles** : `true` (activé) / `false` (désactivé).
- **Effet** : Si activé, le pare-feu est activé pour les profils de réseau (domaine, privé, public), ce qui permet de protéger le système contre les connexions non autorisées.

## 2. RemoteRegistry
- **Description** : Contrôle le service RemoteRegistry (accès distant au registre).
- **Valeurs possibles** : `4` (désactivé) / `3` (manuel) / `2` (automatique) / `1` (démarré).
- **Effet** : Si désactivé, cela empêche l'accès à distance au registre, ce qui est une mesure de sécurité pour éviter les modifications non autorisées.

## 3. PasswordComplexity
- **Description** : Détermine la complexité requise pour les mots de passe des utilisateurs.
- **Valeurs possibles** : `1` (activer la complexité) / `0` (désactiver la complexité).
- **Effet** : Si activée, cela impose une complexité minimale pour les mots de passe, par exemple l'utilisation de lettres, chiffres et caractères spéciaux.

## 4. Geolocation
- **Description** : Active ou désactive les services de géolocalisation de Windows.
- **Valeurs possibles** : `4` (désactivé) / `3` (manuel) / `2` (automatique) / `1` (activé).
- **Effet** : Si désactivée, cela empêche le système d'utiliser les informations de localisation.

## 5. AccountLockoutDuration
- **Description** : Définit la durée de verrouillage d'un compte après un nombre d'échecs de connexion.
- **Valeur en minutes** : Nombre de minutes pendant lesquelles un compte restera verrouillé après plusieurs tentatives de connexion échouées.
- **Effet** : Augmente la sécurité en empêchant les attaques par force brute en verrouillant les comptes après des échecs successifs.

## 6. LanmanServer
- **Description** : Contrôle le service LanmanServer, qui gère les partages réseau sur le système.
- **Valeurs possibles** : `4` (désactivé) / `3` (manuel) / `2` (automatique) / `1` (démarré).
- **Effet** : Désactiver ce service améliore la sécurité en empêchant le partage de fichiers non autorisé.

## 7. MaximumPasswordAge
- **Description** : Définit la durée maximale de validité d'un mot de passe avant qu'il ne doive être changé.
- **Valeur en jours** : Le nombre de jours après lesquels un utilisateur doit changer son mot de passe.
- **Effet** : Cette politique de sécurité oblige les utilisateurs à changer leurs mots de passe après une période déterminée.

## 8. AuditPolicySuccess
- **Description** : Active ou désactive la journalisation des événements réussis dans l'audit de la politique de sécurité.
- **Valeurs possibles** : `enable` / `disable`.
- **Effet** : Si activée, cette option permet de suivre les actions réussies des utilisateurs et administrateurs dans les journaux de sécurité.

## 9. AuditPolicyFailure
- **Description** : Active ou désactive la journalisation des événements échoués dans l'audit de la politique de sécurité.
- **Valeurs possibles** : `enable` / `disable`.
- **Effet** : Si activée, cette option permet de suivre les tentatives échouées d'accès ou d'autres actions de sécurité.

## 10. DisableAutoplay
- **Description** : Contrôle l'auto-exécution des périphériques de stockage (comme les clés USB).
- **Valeurs possibles** : `true` (désactiver) / `false` (activer).
- **Effet** : Si activée, l'auto-exécution des périphériques de stockage est désactivée, ce qui réduit les risques liés aux malwares qui se lancent automatiquement.

## 11. DisableRemoteDesktop
- **Description** : Active ou désactive l'accès au Bureau à distance (Remote Desktop) de Windows.
- **Valeurs possibles** : `true` (désactiver) / `false` (activer).
- **Effet** : Si désactivé, cela empêche les connexions à distance via Remote Desktop, ce qui améliore la sécurité en restreignant l'accès à l'ordinateur.

## 12. EnableUAC
- **Description** : Active ou désactive le Contrôle de compte utilisateur (UAC).
- **Valeurs possibles** : `true` (activer) / `false` (désactiver).
- **Effet** : Si activée, cette fonction demande la confirmation de l'utilisateur pour certaines actions nécessitant des privilèges d'administrateur, ce qui aide à éviter les changements non autorisés.

## 13. DisableAnonymousShareAccess
- **Description** : Empêche l'accès anonyme aux ressources partagées sur le réseau.
- **Valeurs possibles** : `true` (activer) / `false` (désactiver).
- **Effet** : Si activée, cela empêche les utilisateurs anonymes d'accéder aux partages de fichiers ou de ressources réseau, renforçant ainsi la sécurité.

## 14. IPv6
- **Description** : Active ou désactive le protocole IPv6 sur l'interface réseau.
- **Valeurs possibles** : `true` (activer) / `false` (désactiver).
- **Effet** : Si désactivée, IPv6 est désactivé, ce qui peut être utile pour éviter certains vecteurs d'attaque ou des problèmes de compatibilité.

## 15. SSDPDiscovery
- **Description** : Active ou désactive la découverte des périphériques via SSDP (Simple Service Discovery Protocol).
- **Valeurs possibles** : `4` (désactivé) / `3` (manuel) / `2` (automatique) / `1` (activé).
- **Effet** : Si désactivé, cela empêche les périphériques et applications sur le réseau de découvrir automatiquement votre ordinateur, ce qui peut réduire la surface d'attaque.
