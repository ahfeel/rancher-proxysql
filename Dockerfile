FROM proxysql/proxysql:2.4.5

MAINTAINER Jérémie BORDIER <jeremie.bordier@gmail.com>

RUN apt-get update && \
	apt-get install -y curl && \
	apt-get -y clean

VOLUME /var/lib/proxysql

ADD docker-entrypoint.sh /
ADD proxysql.cnf.tpl /etc/proxysql.cnf.tpl

EXPOSE 3306 3307 6032 6080

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/proxysql", "--initial", "-f", "--idle-threads"]
