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

```
yum install unzip git
mkdir /opt/oldsieve/
mkdir /tmp/sieveimport/
unzip /root/all_sieve.zip -d /opt/oldsieve/

git clone https://github.com/wixaw/sieve_to_sogo-import.git /opt/sieve_to_sogo-import
cd /opt/sieve_to_sogo-import/
edit **parser_sieve_folder.sh**  # DIR="/opt/oldsieve/"
edit **roots.cred** qui contient les identifiants du compte root imapd

# Execution du parser
./parser_sieve_folder.sh

# Résultat à executer: 
sogo-tool user-preferences set defaults toto -p root.creds SOGoSieveFilters -f /tmp/sieveimport/toto_sieve.json
sogo-tool user-preferences set defaults titi -p root.creds Forward -f /tmp/sieveimport/titi_forward.json
sogo-tool user-preferences set defaults tata -p root.creds Vacation -f /tmp/sieveimport/tata_vacation.json

```