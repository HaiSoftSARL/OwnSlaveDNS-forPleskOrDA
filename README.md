# OwnSlaveDNS-forPlesk
Helps to retrieve DNS zones from a Plesk server to a secondary DNS server (bind)

Requirements on slave server :
- Bind (named ; named-chroot...)
- MySQL client
- Add option "allow-new-zones yes;" in /etc/named.conf

On the master server, add a SQL user, which will only be able to show the domains :
````sql
CREATE USER 'dns'@'%' identified by 'SomeRandomPasswordYouChoose';
GRANT USAGE ON *.* TO 'dns'@'%' with MAX_QUERIES_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
GRANT SELECT ON psa.domains TO 'dns'@'%';
FLUSH PRIVILEGES;
````
If you want to be more restrictive, you can specify the IP address instead of % in the SQL query.

Still on the master server, from Plesk, you need to add the IP of your slave server to the "Common Allow Zone Transfer ACL" :
Tools & Settings > DNS Template > Transfer Restrictions Template > Add Address

You can then download the script on the slave server :
````bash
cd /opt/ && wget https://raw.githubusercontent.com/MegaS0ra/OwnSlaveDNS-forPlesk/master/slave-retrieve.sh && chmod +x slave-retrieve.sh
````
Edit the script to replace the content of "psa_password" with the password you choosed before.

Execute the script with the IP of the master server as argument :
````bash
/opt/slave-retrieve.sh IP.IP.IP.IP
````
At each execution, the script will check if there are new domains (or removed domains) on the specified host, in comparison to the actual slaves zones, and add/remove these domains.

This script does the job only when executed, so you may want to setup a cron job to execute it.

Also, if you want to execute this script for different master servers, you may run it in a loop for each IP :
````bash
while IFS= read -r i ; do 
	echo "$i" ; /opt/slave-retrieve.sh "$i" < /dev/null
done < IPlist.txt
````

Tested and created on CentOS 7.

--
Inspired by : https://matoski.com/article/bind-slave-dns-automatic-additions-of-zones/
