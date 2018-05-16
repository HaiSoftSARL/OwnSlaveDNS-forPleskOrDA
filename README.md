# OwnSlaveDNS-forPleskOrDA
Helps to retrieve DNS zones from a Plesk or DirectAdmin server to a secondary DNS server (bind)

Requirements on slave server :
- Bind (named ; named-chroot...)
- MySQL client
- Add option "allow-new-zones yes;" in /etc/named.conf

Requirements on master server :
- Allow SQL connection from slave (for Plesk)
- Allow SSH/SQL connection from slave (for DirectAdmin)

For Plesk, on the master server, add a SQL user, which will only be able to show the domains :
````sql
CREATE USER 'dns'@'%' identified by 'SomeRandomPasswordYouChoose';
GRANT USAGE ON *.* TO 'dns'@'%' with MAX_QUERIES_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
GRANT SELECT ON psa.dns_zone TO 'dns'@'%';
FLUSH PRIVILEGES;
````

If you want to be more restrictive, you can specify the IP address instead of % in the SQL query. Here's a "bash version" :
````bash
echo "CREATE USER 'dns'@'IP.IP.IP.IP' identified by 'SomeRandomPasswordYouChoose';" | plesk db
echo "GRANT USAGE ON *.* TO 'dns'@'IP.IP.IP.IP' with MAX_QUERIES_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" | plesk db
echo "GRANT SELECT ON psa.dns_zone TO 'dns'@'IP.IP.IP.IP';" | plesk db
echo "FLUSH PRIVILEGES;" | plesk db
````

Still on the master server, from Plesk, you need to add the IP of your slave server to the "Common Allow Zone Transfer ACL" :
Tools & Settings > DNS Template > Transfer Restrictions Template > Add Address
You can also do this from command line :
````bash
/usr/local/psa/bin/server_dns -u -add-acl IP.IP.IP.IP
````

On a DirectAdmin server, you must add the IP in the "allow-transfer" setion of the /etc/named.conf file.

You can then download the script on the slave server :
````bash
cd /opt/ && wget https://raw.githubusercontent.com/HaiSoftSARL/OwnSlaveDNS-forPleskOrDA/master/slave-retrieve.sh && chmod +x slave-retrieve.sh
````
Edit the script to replace the content of "psa_password" with the password you choosed before.

Execute the script with the IP of the master server as argument :
````bash
/opt/slave-retrieve.sh IP.IP.IP.IP
````
At each execution, the script will check if there are new domains (or removed domains) on the specified host, in comparison to the actual slaves zones, and add/remove these domains.

--

If the script is executed without any argument, it will do the check for the masters already added.

This script does the job only when executed, so you may want to setup a cron job to execute it.

Also, if you want to execute this script for different master servers, you may run it in a loop for each IP :
````bash
while IFS= read -r i ; do 
	echo "$i" ; /opt/slave-retrieve.sh "$i" < /dev/null
done < IPlist.txt
````

--

If the script is executed with the argument -d, it allows to "move" a domain from one master to another :
````
./slave-retrieve.sh -d domain.tld IP1.IP1.IP1.IP1 IP2.IP2.IP2.IP2
````

Tested and created on CentOS 7.

--
Inspired by : https://matoski.com/article/bind-slave-dns-automatic-additions-of-zones/
