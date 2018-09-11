# Percona XtraDB Cluster Docker

The image contains Percona XtraDB Cluster 5.7 based on CentOS 7.

## Usage
1. Create `docker-compose.yml` file and configure instance. Example docker-compose file:
```
version: '2.2'
services:
  db:
    image: "larrabee/percona"
    container_name: "db"
    security_opt:
      - "seccomp:unconfined"
    network_mode: "host"
    ulimits:
      nproc: 65535
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 131072
        hard: 131072
      volumes:
        - "db-data:/var/lib/mysql"
        - "db-backup:/var/lib/mysql-backup"
        - "/etc/pxc/db.cnf:/etc/my.cnf"
        
volumes:
  db-data: {}
  db-backup: {}
```

2. Create mysql config file. I recommend to create it in `/etc/pxc/db.cnf`. Example my.cnf:
```
[mysqld]
server-id = 1
datadir = /var/lib/mysql
log-error = /var/log/stdout.log
log_output = FILE

wsrep_provider = /usr/lib64/galera3/libgalera_smm.so
wsrep_cluster_address = gcomm://
wsrep_node_name = node1
wsrep_node_address = 192.168.1.2
wsrep_sst_method = xtrabackup-v2
wsrep_sst_auth = "user:password"


pxc_strict_mode = ENFORCING
enforce-gtid-consistency = ON
binlog_format = ROW
default_storage_engine = InnoDB
innodb_file_per_table = 1
innodb_autoinc_lock_mode = 2
```
3. Run the image with `docker-compose up -d`. You can view logs with `docker-compose logs -f db`.
4. Change root user password (temporary password showed in the container logs).

## Available environment variables
* `MYSQL_CONFIG_FILE` is path to my.cnf file. Default is `/etc/my.cnf`.
* `MYSQL_SKIP_POSITION_RECOVERY` is disabling IST recovery and perform full sync (with SST).

You can pass any additional args with docker CMD. Its will append to mysqld.
