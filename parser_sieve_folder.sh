#!/bin/bash

################
# Tool Name: Sieve_to_SOGo Sieve import
# Description: Permet de parser le dossier sieve original
# Version: 1.0
# Author: William VINCENT
# Author URI: https://github.com/wixaw
# License: GPLv2
################

PLPATH=`pwd`
DIR="/var/lib/imap/sieve"
if [ -d $DIR ]; then
    cd $DIR
else
    exit;
fi


for initial in * ; do
    cd $DIR/$initial/
    for user in * ; do
        COUNT="${#user}";
        # clean 
        if [[ "$COUNT" == "1" ]]; then 
            continue;
        fi
        # generation de la commande    
        if [ -f ${user}/smartsieve.script ]; then
            perl $PLPATH/sieve_to_sogo-import.pl ${user}/smartsieve.script ${user}
        else
            continue;
        fi
    done

done