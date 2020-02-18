#!/usr/bin/perl -w

################
# Tool Name: Sieve_to_SOGo Sieve import
# Description: Permet d'importer des .sieve dans SOGo via sogo-tools
# Version: 1.0
# Author: William VINCENT
# Author URI: https://github.com/wixaw
# Fork : https://users.sogo.narkive.com/fTWUoHkj/sieve-scripts
# License: GPLv2
################


##########################
# Déclarations 

use strict;
use warnings;
sub convert ($);
sub convertRules ($);
sub convertAction ($$);
sub convertActionSingle ($);
my $sogoSieveVacation = "";
my $sogoSieveForward = "";
my $debug = 0;

##########################
# Main 
if(-e $ARGV[0] && defined $ARGV[1]) { 

    my $file = $ARGV[0];
    my $user = $ARGV[1];
    my $sogoSieve = convert($file);

    my $filenameoutsieve = "/tmp/sieveimport/".$user."_sieve.json";
    my $filenameoutvac = "/tmp/sieveimport/".$user."_vacation.json";
    my $filenameoutfor = "/tmp/sieveimport/".$user."_forward.json";
    open(my $fro, '>', $filenameoutsieve) or die "Could not open file '$filenameoutsieve' $!";
    print $fro "{$sogoSieve}";
    close $fro;
    open(my $fro2, '>', $filenameoutvac) or die "Could not open file '$filenameoutvac' $!";
    print $fro2 "{$sogoSieveVacation}";
    close $fro2;
    open(my $fro3, '>', $filenameoutfor) or die "Could not open file '$filenameoutfor' $!";
    print $fro3 "{$sogoSieveForward}";
    close $fro3;

    print("\nCommandes à executer pour $user: \n");
    print("sogo-tool user-preferences set defaults $user -p root.creds SOGoSieveFilters -f $filenameoutsieve");
    print("\n");
    if ($sogoSieveVacation eq ""){    }else {   
        print("sogo-tool user-preferences set defaults $user -p root.creds Vacation -f $filenameoutvac");
        print("\n");
    }
    
    if ($sogoSieveForward eq ""){    }else {   
        print("sogo-tool user-preferences set defaults $user -p root.creds Forward -f $filenameoutfor");
        print("\n");
    }


}elsif(-e $ARGV[0]) {
    my $file = $ARGV[0];
    my $sogoSieve = convert($file);

    print("\nCommandes à executer:\n\n");
    print("sogo-tool user-preferences set defaults user -p root.creds SOGoSieveFilters {$sogoSieve}");
    print("\n\n");
    print("sogo-tool user-preferences set defaults user -p root.creds Vacation {$sogoSieveVacation}");
    print("\n\n");
    print("sogo-tool user-preferences set defaults user -p root.creds Forward {$sogoSieveForward}");
    print("\n\n");
} else {
    print("############### sieve_to_sogo-import.pl ##################\n");
    print("# -Creer un fichier tmp :\n");
    print("# ./sieve_to_sogo-import.pl filesieve.script user\n");
    print("# -Afficher le résultat :\n");
    print("# ./sieve_to_sogo-import.pl filesieve.script\n");
    print("# -Creer le fichier des identifiants root du serveur imapd\n");
    print("# echo 'root:passwd' > root.creds\n");
    print("# -Creer le dossier tmp \n");
    print("# mkdir /tmp/sieveimport/ \n");
    print("#  \n");
}

##########################
# Fonctions 

# Fonction principale qui traite ligne par ligne le fichier en entrée
sub convert($) {
    my $file = shift;
    my $rules = "";
    my $action = "";
    my $name = "";
    my $shortname = "";
    my $string = "";
    my $filters = "";
    my $filtertmp = "";
    my $rejectMode = "false";
    my $rejectContent = "";
    my $vacationMode = "false";
    my $vacationContent = "";
    my $forwardMode = "false";
    my $forwardContent = "";

    open(my $fh, '<', $file) or die "Could not open file '$file' $!";
    my $count = 0;
    my $type = "???";

    while (my $row = <$fh>) {
        # On compte les lignes pour savoir d'ou viennent les erreurs
        $count ++;
        chomp $row;
        $row =~ s/(\r?\n|\r\n?)+$//;

        if ($debug eq 1) { 
            print "$row\n";
        }

        # On passe les lignes vides, les commentaires et le require
        if ($row =~ /^\s*$/){
            next;
        }

        if ($row =~ /^#/){
            next;
        }

        if ($row =~ /^require/){
            next;
        }

        # TRAITEMENT DES CONDITIONS
        if($row =~ /\s*if (allof|anyof) \((.*)\)/) {
            $rules = convertRules($2);
            $type = "???";
            if ($debug eq 1) { print("$1 $2 de $file\n"); }

            if ("$1" eq "allof"){
                $type = "all";
            }

            if ("$1" eq "anyof"){
                $type = "any"; 
            }
            
            $string = $2;
            $string =~ tr/"/'/;
            $shortname .= "($string) ";
            next;
        } 
        if($row =~ /\s*if\s+([^\(]*")/) {
            $rules = convertRules($1);
            $type = "unknow";
            print("Type $1 unknow ! ");
            exit;
        } 

        # TRAITEMENT DES "redirect" (forward) doit etre avant "traitement des action" car priorité sur ^redirect
        if($row =~ /^redirect \"(.*)\";/) {
            $forwardMode="true";
            $forwardContent="$1";
            next;
        }
        if ( $forwardMode eq "true") {
            if($row =~ /^keep/) {
                $sogoSieveForward="{\"forwardAddress\": [\"$forwardContent\"], \"enabled\": 1, \"keepCopy\": 1}";
                $forwardMode="false";
                next;
            }else{
                $sogoSieveForward="{\"forwardAddress\": [\"$forwardContent\"], \"enabled\": 1, \"keepCopy\": 0}";
                $forwardMode="false";
            }
        }   


        # TRAITEMENT DES ACTIONS avec arguments
        if($row =~ /\s*(fileinto|addflag|redirect|)\s*"([^"]+)";/) {
            if ( $action eq "" ) {
                $action .= convertAction($1, $2);
            }else {
                $action .= ",".convertAction($1, $2);
            }
            $shortname .= "($1 -> $2) ";
            next;
        }

        # TRAITEMENT DES ACTIONS sans arguments
        if($row =~ /\s*(discard|stop|keep);/) {
            if ( $action eq "" ) {
                $action .= convertActionSingle($1); 
            }else {
                $action .= ",".convertActionSingle($1); 
            }
            $shortname .= "($1) ";
            next;
        }  

        # TRAITEMENT DES "reject"
        if($row =~ /\s*reject text:/) {
            $rejectMode="true";
            $shortname .= "(reject) ";
            next;
        } 
        if ( $rejectMode eq "true") {
            if($row =~ /^;/) {
                $rejectMode="false";
                $filtertmp = "{\"actions\": [{\"method\": \"reject\", \"argument\": \"$rejectContent\"}], \"active\": 1, \"rules\": [$rules], \"match\": \"$type\",\"name\": \"$shortname ($type)\"}";
                
                if($filters eq "") {
                    $filters .= $filtertmp;
                }else{
                    $filters .= ",".$filtertmp;
                }
                $action ="";
                $shortname = "";
            }else {
                $rejectContent .= $row;
            }
            next;
        } 

        # TRAITEMENT DES FINS D'ACTIONS
        if($row =~ /\s*}\s*/) {
        
            $filtertmp = "{\"actions\": [$action], \"active\": 1, \"rules\": [$rules], \"match\": \"$type\",\"name\": \"$shortname ($type)\"}";

            if($filters eq "") {
                $filters .= $filtertmp;
            }else{
                $filters .= ",".$filtertmp;
            }
            $action ="";
            $shortname = "";
            next;
        } 

        # TRAITEMENT DES "vacation"
        if($row =~ /^vacation :days (.*) :addresses ([^\)]*) text:/) {
            $vacationMode="true";
            if ( $sogoSieveVacation eq "" ) {
                $sogoSieveVacation = "vacation: {\"daysBetweenResponse\": $1, \"enabled\": 1, \"autoReplyEmailAddresses\": $2, \"endDate\": 1582066800, \"autoReplyText\": \"TXT\", \"startDateEnabled\": 1, \"discardMails\": 1, \"ignoreLists\": 0, \"endDateEnabled\": 1, \"startDate\": 1581894000} ";
            }    
            next;        
        } 
        if($row =~ /^vacation :days (.*) text:/) {
            $vacationMode="true";
            if ( $sogoSieveVacation eq "" ) {
                $sogoSieveVacation = "vacation: {\"daysBetweenResponse\": $1, \"enabled\": 1, \"endDate\": 1582066800, \"autoReplyText\": \"TXT\", \"startDateEnabled\": 1, \"discardMails\": 1, \"ignoreLists\": 0, \"endDateEnabled\": 1, \"startDate\": 1581894000} ";
            }    
            next;        
        }         
        if ( $vacationMode eq "true"){
            if($row =~ /^;/) {
                $vacationMode="false";
                # SED to sogoSieveVacation TXT par $vacationMode
                $sogoSieveVacation =~s/TXT/$vacationContent/ig;   
            }else {
                $vacationContent .= $row."";
            } 
            next;           
        } 

        # Si on est rentré dans aucun cas, alors c'est une erreur 
        print("Parse Error in line \"$count\" ($file) \n\"$row\"\n");
        exit;

    }
    return "\"SOGoSieveFilters\":[$filters]";
    close $fh;
}


# Fonction : traitement des conditions
sub convertRules($) {
    my $in = shift;
    my $rules = "";
    my @entities = split(/, /, $in);
    my $new2;my $new1;
    for(@entities) {
        if($_ =~ /\s*not header\s+:(matches|contains|is|regex|)\s+"([^"]+)"\s+"([^"]+)"\s*/) {
            $new1 = $1."_not";
            if($rules eq "") {
                $rules .= "{\"operator\": \"$new1\", \"field\": \"" . $2 . "\", \"value\": \"$3\"}";
            }else {
                $rules .= ",{\"operator\": \"$1\", \"field\": \"" . lc($2) . "\", \"value\": \"$3\"}";    
            } 
        }elsif($_ =~ /\s*header\s+:(matches|contains|is|regex|)\s+"([^"]+)"\s+"([^"]+)"\s*/) {
            if($rules eq "") {
                $rules .= "{\"operator\": \"$1\", \"field\": \"" . $2 . "\", \"value\": \"$3\"}";
            }else {
                $rules .= ",{\"operator\": \"$1\", \"field\": \"" . lc($2) . "\", \"value\": \"$3\"}";    
            }
        }elsif($_ =~ /size :(over|under) (.*)/) {
            if($rules eq "") {
                $rules .= "{\"operator\": \"size\", \"field\": \"" . $1 . "\", \"value\": \"$2\"}";
            }else {
                $rules .= ",{\"operator\": \"size\", \"field\": \"" . $1 . "\", \"value\": \"$2\"}";    
            }
        }elsif ($_ =~ /\s*not address\s+:(matches|contains|is|)\s+(.+)\s+"\(?(.*)\)?"\s*/) {
            $new1 = $1."_not";
            $new2 = $2 ; 
            if ( "$2" eq "\"from\""){
                $new2 = "from";
            }
            if ( "$2" eq "\"to\""){
                $new2 = "to";
            }
            if ( "$2" eq "[\"to\",\"cc\"]"){
                $new2 = "to_or_cc";
            }
            if($rules eq "") {
                $rules .= "{\"operator\": \"$new1\", \"field\": \"" . lc($new2) . "\", \"value\": \"$3\"}";
            }else {
                $rules .= ",{\"operator\": \"$new1\", \"field\": \"" . lc($new2) . "\", \"value\": \"$3\"}";    
            }           
        }elsif ($_ =~ /\s*address\s+:(matches|contains|is|)\s+(.+)\s+"\(?(.*)\)?"\s*/) {
            $new2 = $2 ; 
            if ( "$2" eq "\"from\""){
                $new2 = "from";
            }
            if ( "$2" eq "\"to\""){
                $new2 = "to";
            }
            if ( "$2" eq "[\"to\",\"cc\"]"){
                $new2 = "to_or_cc";
            }
            if($rules eq "") {
                $rules .= "{\"operator\": \"$1\", \"field\": \"" . lc($new2) . "\", \"value\": \"$3\"}";
            }else {
                $rules .= ",{\"operator\": \"$1\", \"field\": \"" . lc($new2) . "\", \"value\": \"$3\"}";    
            }  
        } else {
            print("!!!!!!!!!!!!!!!!!!!!ERROR: Unknown rule:\n$_\n");
            return "false";
        }

        if ($debug eq 1) { print "#Rule : $rules\n"; }
    }
    return $rules;
}

# Fonction : traitement des actions avec arguments
sub convertAction($$) {
    my $method = shift;
    my $argument = shift;
    $argument =~ s/\./\//g;
    my $newarg;
    $newarg = $argument ; 
    if ( "$argument" =~ "\\Seen"){
        $newarg = "seen";
    }
    # on nettoie les espaces qui genere des erreurs
    $newarg =~ s/\s*$//;
    return "{\"method\": \"$method\", \"argument\": \"$newarg\"}"; 
}

# Fonction : traitement des actions sans arguments
sub convertActionSingle($) {
    my $method = shift;
    return "{\"method\": \"$method\"}"; 
}