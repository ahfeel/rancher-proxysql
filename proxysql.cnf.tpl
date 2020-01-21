datadir="/var/lib/proxysql"

admin_variables=
{
	admin_credentials="admin:admin"
	mysql_ifaces="0.0.0.0:6032"
	admin-web_enabled=%STATS_WEB_ENABLED%
	admin-stats_credentials="stats:%STATS_USER_PASSWORD%"
}

mysql_variables=
{
	threads=4
	max_connections=2048
	default_query_delay=0
	default_query_timeout=36000000
	have_compress=true
	poll_timeout=2000
	interfaces="0.0.0.0:3306"
	default_schema="information_schema"
	stacksize=1048576
	server_version="5.5.30"
	connect_timeout_server=3000
	monitor_username="%MONITOR_USER%"
	monitor_password="%MONITOR_PASSWORD%"
	monitor_history=600000
	monitor_connect_interval=60000
	monitor_ping_interval=10000
	monitor_read_only_interval=1500
	monitor_read_only_timeout=500
	ping_interval_server_msec=120000
	ping_timeout_server=500
	commands_stats=true
	sessions_sort=true
	connect_retries_on_failure=10
	monitor_writer_is_also_reader=true
}

mysql_users:
(
	{
		username="%MYSQL_USER%"
		password="%MYSQL_PASSWORD%"
		default_hostgroup=10
		max_connections=1000
		active=1
		transaction_persistent=1
	}
)

mysql_replication_hostgroups=
(
	{
		writer_hostgroup=10
		reader_hostgroup=20
		comment="host groups"
	}
)

mysql_query_rules:
(
	{
		rule_id=1
		active=1
		match_pattern="^SELECT .* FOR UPDATE$"
		destination_hostgroup=10
		apply=1
	},
	{
		rule_id=2
		active=1
		match_pattern="^SELECT .*SQL_CALC_FOUND_ROWS .*|^SELECT .*FOUND_ROWS().*)"
		destination_hostgroup=10
		apply=1
	},
	{
		rule_id=3
		active=1
		match_pattern="^SELECT"
		destination_hostgroup=20
		apply=1
	}
)
