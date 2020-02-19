#!/bin/bash

################
# Tool Name: Sieve_to_SOGo Sieve import
# Description: Permet de parser le dossier sieve original
# Version: 1.0
# Author: William VINCENT
# Author URI: https://github.com/wixaw
# License: GPLv2
################

# On test si le dossier existe, sinon on quit le programme
PLPATH=`pwd`
SIEVEDIR="/opt/oldsieve/"
if [ -d $SIEVEDIR ]; then
    cd $SIEVEDIR
else
    exit;
fi

# MAIN 
# On boucle sur tous les répertoires a/, b/, c/ ... 
for initial in * ; do
    cd $SIEVEDIR/$initial/
    # On boucle sur les répertoires utilisateurs toto/, titi/, tata/ ...
    for user in * ; do
        COUNT="${#user}";
        # On clean les répertoires problematiques comme a/a/, b/b/ ...
        if [[ "$COUNT" == "1" ]]; then 
            continue;
        fi
        # Execution de la commande perl 
        if [ -f ${user}/smartsieve.script ]; then
            perl $PLPATH/sieve_to_sogo-import.pl ${user}/smartsieve.script ${user}
        else
            continue;
        fi
    done
done