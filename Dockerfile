FROM debian:jessie

MAINTAINER Jérémie BORDIER <jeremie.bordier@gmail.com>

ARG PROXYSQL_VERSION=1.4.1

RUN apt-get update && \
	apt-get install -y mysql-client curl netcat && \
	apt-get -y clean

RUN curl -L -o /tmp/proxysql.deb https://github.com/sysown/proxysql/releases/download/v${PROXYSQL_VERSION}/proxysql_${PROXYSQL_VERSION}-debian8_amd64.deb && \
	dpkg -i /tmp/proxysql.deb && \
	rm /tmp/proxysql.deb

RUN cp /etc/proxysql.cnf /etc/proxy.cnf.orig

VOLUME /var/lib/proxysql

ADD docker-entrypoint.sh /

EXPOSE 3306 6032

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/proxysql", "--initial", "-f"]