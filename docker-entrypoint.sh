#!/bin/bash

: ${MYSQL_SERVICE_NAME:=mysql}
: ${PROXYSQL_PORT:=3306}
: ${PROXYSQL_WRITER_PORT:=3307}
: ${PROXYSQL_STATS_USER_PASSWORD:=stats}
: ${PROXYSQL_STATS_WEB_ENABLED:=false}

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

cp /etc/proxysql.cnf.tpl /etc/proxysql.cnf

sed -i -E "s/interfaces=\"(.*):.*,(.*):.*\"/interfaces=\"\1:${PROXYSQL_PORT},\2:${PROXYSQL_WRITER_PORT}\"/" /etc/proxysql.cnf
sed -i -E "s/%MONITOR_USER%/${MYSQL_MONITOR_USER}/" /etc/proxysql.cnf
sed -i -E "s/%MONITOR_PASSWORD%/${MYSQL_MONITOR_PASSWORD}/" /etc/proxysql.cnf
sed -i -E "s/%MYSQL_USER%/${MYSQL_PROXY_USER}/" /etc/proxysql.cnf
sed -i -E "s/%MYSQL_PASSWORD%/${MYSQL_PROXY_PASSWORD}/" /etc/proxysql.cnf
sed -i -E "s/%STATS_WEB_ENABLED%/${PROXYSQL_STATS_WEB_ENABLED}/" /etc/proxysql.cnf
sed -i -E "s/%STATS_USER_PASSWORD%/${PROXYSQL_STATS_USER_PASSWORD}/" /etc/proxysql.cnf

echo "
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
	echo "{ address=\"${container}\" , port=3306 , hostgroup=20, max_connections=500, max_replication_lag=20 }" >> /etc/proxysql.cnf
	FIRST="0"
done

echo ")" >> /etc/proxysql.cnf

exec "$@"