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

# Start fresh

cp /etc/proxysql.cnf.orig /etc/proxysql.cnf

sed -i -E "s/interfaces=\"(.*):.*\"/interfaces=\"\1:${PROXYSQL_PORT}\"/" /etc/proxysql.cnf
sed -i -E "s/monitor_username=\"(.*)\"/monitor_username=\"${MYSQL_MONITOR_USER}\"/" /etc/proxysql.cnf
sed -i -E "s/monitor_password=\"(.*)\"/monitor_password=\"${MYSQL_MONITOR_PASSWORD}\"/" /etc/proxysql.cnf

echo "mysql_replication_hostgroups=
(
	{
		writer_hostgroup=10
		reader_hostgroup=20
		comment=\"host groups\"
	}
)

mysql_query_rules:
(
	{
		rule_id=1
		active=1
		match_pattern=\"^SELECT .* FOR UPDATE$\"
		destination_hostgroup=10
		apply=1
	},
	{
		rule_id=2
		active=1
		match_pattern=\"^SELECT\"
		destination_hostgroup=20
		apply=1
	}
)

mysql_users:
(
	{
		username = \"${MYSQL_PROXY_USER}\"
		password = \"${MYSQL_PROXY_PASSWORD}\"
		default_hostgroup = 10
		max_connections=10000
		active = 1
	}
)

mysql_servers =
(
" >> /etc/proxysql.cnf

# Register containers found through Rancher Metadata API
FIRST="1"
for container in $(curl -s http://rancher-metadata/latest/services/${MYSQL_SERVICE_NAME}/containers | sed 's/.=//g'); do
	echo "Registering MySQL instance ${container}"
	if [ $FIRST != "1" ]; then
		echo "," >> /etc/proxysql.cnf
	fi
	echo "{ address=\"${container}\" , port=3306 , hostgroup=10, max_connections=500 }"
	FIRST="0"
done

echo ")" >> /etc/proxysql.cnf

exec "$@"