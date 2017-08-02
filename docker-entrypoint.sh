#!/bin/bash

: ${MYSQL_SERVICE_NAME:=mysql}
: ${PROXYSQL_PORT:=3306}

if [ -z "${MYSQL_PROXY_USER}" ]; then
	echo "Missing MYSQL_PROXY_USER environment variable."
	exit 1
fi

if [ -z "${MYSQL_PROXY_PASSWORD}" ]; then
	echo "Missing MYSQL_PROXY_PASSWORD environment variable."
	exit 1
fi

if [ -z "${MYSQL_MONITOR_USER}" ]; then
	echo "Missing MYSQL_MONITOR_USER environment variable."
	exit 1
fi

if [ -z "${MYSQL_MONITOR_PASSWORD}" ]; then
	echo "Missing MYSQL_MONITOR_PASSWORD environment variable."
	exit 1
fi

sed -i -E "s/interfaces=\"(.*):.*\"/interfaces=\"\1:${PROXYSQL_PORT}\"/" /etc/proxysql.cnf
sed -i -E "s/monitor_username=\"(.*)\"/monitor_username=\"${MYSQL_MONITOR_USER}\"/" /etc/proxysql.cnf
sed -i -E "s/monitor_password=\"(.*)\"/monitor_password=\"${MYSQL_MONITOR_PASSWORD}\"/" /etc/proxysql.cnf

service proxysql initial

# Wait for ProxySQL to start
while ! nc -z localhost 6032; do   
  sleep 0.1
done

# Register containers found through Rancher Metadata API
for container in $(curl -s http://rancher-metadata/latest/services/${MYSQL_SERVICE_NAME}/containers | sed 's/.=//g'); do
	echo "Registering MySQL instance ${container}"
	mysql -h 127.0.0.1 -P6032 -uadmin -padmin -e "INSERT INTO mysql_servers (hostgroup_id, hostname, port, max_replication_lag) VALUES (0, '${container}', 3306, 10)"
done

mysql -h 127.0.0.1 -P6032 -uadmin -padmin -e "INSERT INTO mysql_users (username, password, active, default_hostgroup, max_connections) VALUES ('${MYSQL_PROXY_USER}', '${MYSQL_PROXY_PASSWORD}', 1, 0, 200);"
mysql -h 127.0.0.1 -P6032 -uadmin -padmin -e "LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK; LOAD MYSQL USERS TO RUNTIME; SAVE MYSQL USERS TO DISK;"

service proxysql stop

exec "$@"