#!/bin/bash

# Définition des constantes
psa_user="dns"
psa_password="noh4icaigh2weiGaiph3sahDoeThaequ5HeGha2oeMeezee6re"
psa_db="psa"
psa_sql="select name from dns_zone where status=0 and type='master'"
script_name=$(basename "$0")
export "$(grep -v ^# /etc/sysconfig/named | grep ROOTDIR | xargs)"
temp=$(grep directory /etc/named.conf | awk '{print $2}') ; temp=${temp//\"/} ; named_dir=${temp//\;/}
fulldir=$ROOTDIR$named_dir

if [ "$1" == "-h" ]
then
        echo "Usage :"
        echo "If an IP address is passed as an argument, the script will retreive DNS zones from this IP."
        echo "If no agrument is passed, the script will check the DNS zones for the IP adresses that have already been added."
        exit
fi

if [ -n "$2" ]
then
        echo "Too much arguments"
        exit
fi

if [ -z "$1" ]
then
        ls "$fulldir"/slaves/ > /opt/SrvList.txt
        var=$(cat /opt/SrvList.txt)
        if [ -z "$var" ] ; then echo "No master yet. Please run the script followed by an IP address at least once." ; rm -f /opt/SrvList.txt ; exit ; fi
else
        var=$1
fi

printf '%s\n' "$var" | while IFS= read -r i ; do

        psa_host=$i
        echo -e "\\nVérification des zones sur le serveur $i\\n"

        # Création de répertoire
        if [ ! -d "$fulldir"/slaves/"$psa_host" ];
        then
            mkdir "$fulldir"/slaves/"$psa_host"
            chown named:named "$fulldir"/slaves/"$psa_host"
        fi

        # Exécution de la requête SQL et stockage du résultat dans un fichier et dans une variable
        echo "$psa_sql" | mysql -N -h"$psa_host" -u"$psa_user" -p"$psa_password" "$psa_db" > /opt/dns1zones.txt

        # Récupération de la liste des zones présentes sur le serveur secondaire et stockage dans un fichier
        touch /opt/dns2zones.txt
        find "$fulldir"/slaves/"$psa_host" -maxdepth 1 -type f -printf "%f\\n" > /opt/dns2zones.txt

        # Compare la liste des domaines présents dans slaves/$psa_host avec liste des domaines du serveur d'origine
        # Les domaines indiqués par cette commande sont les domaines à ajouter (addzone)
        domtoadd=$(grep -Fxv -f /opt/dns2zones.txt /opt/dns1zones.txt)

        # Compare la liste des domaines du serveur d'origine avec la liste des domaines présents dans slaves/$psa_host
        # Les domaines indiqués par cette commande sont les domaines à supprimer (delzone)
        domtodel=$(grep -Fxv -f /opt/dns1zones.txt /opt/dns2zones.txt)

        if [ -z "$domtoadd" ]
        then
            echo -e "$(date "+%d/%m/%Y %T") - No domain to add\\n"
            logger -t "$script_name" -- "No domain to add."
        else
            for domain_a in $domtoadd
            do
                addcommand="/usr/sbin/rndc addzone $domain_a '{type slave; file \"slaves/${psa_host}/${domain_a}\"; masters { $psa_host; }; };'"
                eval "$addcommand"
                echo -e "$(date "+%d/%m/%Y %T") - Adding domain: $domain_a\\n"
                logger -t "$script_name" -- "/usr/sbin/rndc addzone $addcommand"

                /usr/sbin/rndc reload
            done
        fi

        if [ -z "$domtodel" ]
        then
            echo -e "$(date "+%d/%m/%Y %T") - No domain to remove\\n"
            logger -t "$script_name" -- "No domain to remove."
        else
            for domain_d in $domtodel
            do
                delcommand="/usr/sbin/rndc delzone $domain_d"
                eval "$delcommand"
                rm -f "$fulldir"/slaves/"$psa_host"/"$domain_d"
                echo -e "$(date "+%d/%m/%Y %T") - Removing domain: $domain_d\\n"
                logger -t "$script_name" -- "/usr/sbin/rndc delzone $domain_d"

                /usr/sbin/rndc reload
            done
        fi

        rm -f /opt/dns1zones.txt /opt/dns2zones.txt /opt/IPlist.txt
done
