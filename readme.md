# Sieve_to_SOGo sieve import

- Ces scripts permettent d'importer d'ancien fichier sieve, générer avec smartsieve par exemple et de les integrer à SOGo.
- A customiser selon vos configurations :) 

## Fonctionnement 
- Exemple avec smartsieve qui génere pour chaque utilisateur un fichier smartsieve.script 
- Le répertoire de sieve est parser par un script bash. 
- Pour chaque utilisateur trouver, il execute "sieve_to_sogo-import.pl smartsieve.script $username"
- Deux fichiers temporaire sont creer dans /tmp/sieveimport/ au format json, 
- La commande SOGo est executer ou afficher c'est à modifier dans le script

## Migration 
- Couper l'éditeur de sieve actuel ( dans mon cas smartsieve à desactiver de mon serveur apache)
- Copier tout le dossier sieve du serveur imapd ( cd /var/lib/imap/sieve/ ; zip -r /tmp/all_sieve.zip ./) 
- sur le serveur SOGo ( scp /tmp/all_sieve.zip root@sogo:/tmp/ ) 
- Depuis le serveur SOGo editer et utiliser parser_sieve_folder.sh pour parcourir le répertoire de sieve et procéder à l'import.
- Le programme par défaut liste les commandes sogo-tool à effectuer et creer les fichiers .json, ceci permet de voir si tout les règles sont bien reconnu auquel cas il faudra, soit modifier le sieve original, soit modifier le perl si c'est trop redondant.
- Si vous êtes sur, vous pouvez set la variable exec pour executer les commandes sogo-tool

```
yum install unzip git
mkdir /opt/oldsieve/
mkdir /tmp/sieveimport/
unzip /root/all_sieve.zip -d /opt/oldsieve/

git clone https://github.com/wixaw/sieve_to_sogo-import.git /opt/sieve_to_sogo-import
cd /opt/sieve_to_sogo-import/
edit **parser_sieve_folder.sh**  # DIR="/opt/oldsieve/"
edit **sieve_to_sogo-import.pl** # Remplacer smartsieve par le nom de votre ancien sieve manager
edit **sieve_to_sogo-import.pl** # $exec=1 pour executer les commandes sogo-tool, uniquement si vous êtes sur 
edit **roots.cred** qui contient les identifiants du compte root imapd

# Execution du parser
./parser_sieve_folder.sh

# Résultat à executer: 
sogo-tool user-preferences set defaults toto -p root.creds SOGoSieveFilters -f /tmp/sieveimport/toto_sieve.json
sogo-tool user-preferences set defaults titi -p root.creds Forward -f /tmp/sieveimport/titi_forward.json
sogo-tool user-preferences set defaults tata -p root.creds Vacation -f /tmp/sieveimport/tata_vacation.json

# Utilisation de la commande perl pour debuger 
perl sieve_to_sogo-import.pl opt/oldsieve/t/toto/smartsieve.script # Affiche tout dans la console
perl sieve_to_sogo-import.pl opt/oldsieve/t/toto/smartsieve.script toto # Creer les fichiers json et affiche la commande sogo-tool

```

## Probleme connu
- Si dans le fichier sieve.script, si un argument comme un sujet de mail contient une virgule, le split ne fonctionne pas. et donc la règle est en erreur. La solution est d'enlever celle ci et de la rajouter au fichier json une fois créer.
- J'ai eu à faire à quelques fichiers .script qui semblaient être compilé 