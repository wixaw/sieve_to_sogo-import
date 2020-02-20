# Sieve_to_SOGo sieve import
- These scripts import old sieve <toolname> .script files and integrate them with SOGo. It works with smartsieve
- To customize for your configurations :)

## Description 
- The sieve directory is parsed by a bash script.
- For each user to find, it executes "sieve_to_sogo-import.pl smartsieve.script $username"
- Temporary files are created in /tmp/sieveimport/ in json format,
- The SOGo command is to execute or display it is to modify in the script (exec = 0/1)

## Migration exemple 
- Deactivate the current sieve editor (in our case smartsieve to deactivate from the apache server)
- Zip the sieve folder of the imapd server (cd /var/lib/imap/sieve/; zip -r /tmp/all_sieve.zip ./)
- From the IMAPD server send the zip to the SOGo server (scp /tmp/all_sieve.zip root @ sogo:/tmp /)
- From the SOGo server edit and use parser_sieve_folder.sh to browse the sieve directory and proceed with the import.
- By default the program lists the sogo-tool commands to perform and create the .json files, this allows to see if all the rules are well recognized in which case it will be necessary either to modify the original sieve, or to modify the perl if it is too redundant.
- If you are sure, you can set the exec variable to execute the sogo-tool commands

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

## Known issue 
- In the sieve.script file, if an argument like a mail subject contains a comma, the split does not work. The rule is in error. The solution is to remove this one and add it to the json file once created.
- I had to deal with a few .script files which seemed to be compiled