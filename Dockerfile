FROM centos:7

ENV MYSQL_CONFIG_FILE="/etc/my.cnf"
ENV MYSQL_STDOUT_FILE="/var/log/stdout.log"
ENV MYSQL_STDERR_FILE="/var/log/stderr.log"

ARG MYSQL_USER_ID=3301
ARG MYSQL_GROUP_ID=3301
ARG MYSQL_USER_HOMEDIR="/var/lib/mysql"
ARG MYSQL_BACKUP_DIR="/var/lib/mysql-backup"

RUN groupadd -g ${MYSQL_GROUP_ID} mysql && useradd -d "${MYSQL_USER_HOMEDIR}" -g ${MYSQL_GROUP_ID} -M -s "/bin/bash" -u ${MYSQL_USER_ID} mysql

RUN yum install -y http://repo.percona.com/centos/7/os/x86_64/percona-release-0.1-4.noarch.rpm && yum install -y epel-release && yum update -y && yum install -y Percona-XtraDB-Cluster-57 pigz pv && yum clean all
COPY entrypoint.sh /entrypoint.sh
RUN ln -sf /dev/stdout "${MYSQL_STDOUT_FILE}" && ln -sf /dev/stderr "${MYSQL_STDERR_FILE}"
RUN mkdir "${MYSQL_BACKUP_DIR}"  && chown mysql:mysql  "${MYSQL_BACKUP_DIR}"

USER mysql:mysql
VOLUME "${MYSQL_USER_HOMEDIR}"
VOLUME "${MYSQL_BACKUP_DIR}"
ENTRYPOINT ["/entrypoint.sh"]
CMD [""]
