# Rancher ready ProxySQL image

This image will automatically discover the available MySQL nodes and configure a ProxySQL node with proper Read/Write split accross the nodes.

Environment Variables:

Variable               | Mandatory | Comments
-----------------------|-----------|-------------------------------------------------------------------------------
MYSQL_PROXY_USER       | yes       | User ProxySQL will use to connect to MySQL (for user queries)
MYSQL_PROXY_PASSWORD   | yes       | Password for the above user
MYSQL_MONITOR_USER     | yes       | ProxySQL Monitor user for MySQL (used to detect topology and failovers)
MYSQL_MONITOR_PASSWORD | yes       | Password for the above user
MYSQL_SERVICE_NAME     | No        | Name of the MySQL service (default: mysql)
PROXYSQL_PORT          | No        | Port where ProxySQL will listen (actual proxy port, not admin. Default: 3306)
