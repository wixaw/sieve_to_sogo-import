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
- Copier tout le dossier sieve du serveur imapd ( /var/lib/imap/sieve/ ) sur le serveur SOGo
- Depuis le serveur SOGo utiliser parser_sieve_folder.sh pour parcourir le répertoire de sieve et procéder à l'import.