FROM knappek/hadoop-secure:2.7.4
MAINTAINER jtstorck

ARG hdp_repo_os=centos6
ARG hdp_repo_path=2.x/updates
ARG hdp_repo_version=2.6.1.0

# rebuild rpm database and install yum-plugin-ovl to address "Rpmdb checksum is invalid: dCDPT(pkg checksums)" errors on docker
RUN sudo rm -f /var/lib/rpm/__db*; sudo db_verify /var/lib/rpm/Packages; sudo rpm --rebuilddb; yum install -y yum-plugin-ovl

# install wget and add HDP repo to yum
RUN yum -y install wget && wget -nv http://public-repo-1.hortonworks.com/HDP/$hdp_repo_os/$hdp_repo_path/$hdp_repo_version/hdp.repo -O /etc/yum.repos.d/hdp.repo

# zookeeper
RUN yum -y install zookeeper-server
RUN ln -s /usr/hdp/current/zookeeper-server /usr/local/zookeeper
ENV ZOO_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOO_HOME/bin
RUN mkdir /tmp/zookeeper

# hbase
RUN yum -y install hbase
RUN ln -s /usr/hdp/current/hbase-master /usr/local/hbase
ENV HBASE_HOME /usr/local/hbase
ENV PATH $PATH:$HBASE_HOME/bin
RUN rm $HBASE_HOME/conf/hbase-site.xml
COPY config_files/hbase-site.xml $HBASE_HOME/conf/hbase-site.xml

# phoenix
RUN yum install python-argparse.noarch -y
RUN yum -y install phoenix
RUN ln -s /usr/hdp/current/phoenix-server /usr/local/phoenix
ENV PHOENIX_HOME /usr/local/phoenix
ENV PATH $PATH:$PHOENIX_HOME/bin
# TODO need to work around copying explicit versin of phoenix-core jar
#RUN cp $PHOENIX_HOME/lib/phoenix-core-4.7.0.2.6.1.0-129.jar $HBASE_HOME/lib/phoenix.jar

# Kerberos client
RUN yum install krpb5-libs krb5-workstation krb5-auth-dialog -y
RUN mkdir -p /var/log/kerberos
RUN touch /var/log/kerberos/kadmind.log

# Kerberos HBase
COPY config_files/hbase-server.jaas $HBASE_HOME/conf/hbase-server.jaas
COPY config_files/hbase-client.jaas $HBASE_HOME/conf/hbase-client.jaas
COPY config_files/hbase-env.sh $HBASE_HOME/conf/hbase-env.sh
RUN cp /usr/local/hadoop/etc/hadoop/core-site.xml $HBASE_HOME/conf/core-site.xml
RUN mkdir -p /apps/hbase/staging && chmod 711 /apps/hbase/staging

# Kerberos Phoenix
RUN ln -sf $HBASE_HOME/conf/hbase-site.xml $PHOENIX_HOME/bin/hbase-site.xml
RUN ln -sf /usr/local/hadoop/etc/hadoop/core-site.xml $PHOENIX_HOME/bin/core-site.xml
RUN ln -sf /usr/local/hadoop/etc/hadoop/hdfs-site.xml $PHOENIX_HOME/bin/hdfs-site.xml

# Kerberos Zookeeper
COPY config_files/zookeeper-server.jaas $ZOO_HOME/conf/zookeeper-server.jaas
COPY config_files/zookeeper-client.jaas $ZOO_HOME/conf/zookeeper-client.jaas
COPY config_files/zookeeper-env.sh $ZOO_HOME/conf/zookeeper-env.sh
COPY config_files/zoo.cfg $ZOO_HOME/conf/zoo.cfg

# hadoop env variables
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_BIN_HOME $HADOOP_PREFIX/bin
ENV NM_CONTAINER_EXECUTOR_PATH $HADOOP_PREFIX/bin/container-executor
# default environment variables
ENV KRB_REALM EXAMPLE.COM
ENV DOMAIN_REALM example.com
ENV KERBEROS_ADMIN admin/admin
ENV KERBEROS_ADMIN_PASSWORD admin
ENV KERBEROS_ROOT_USER_PASSWORD password
ENV KEYTAB_DIR /etc/security/keytabs
ENV HBASE_KEYTAB_FILE $KEYTAB_DIR/hbase.keytab
ENV ZOOKEEPER_KEYTAB_FILE $KEYTAB_DIR/zookeeper.keytab
ENV PATH $PATH:$HADOOP_BIN_HOME
ENV FQDN hadoop.com

# bootstrap phoenix
ADD bootstrap-phoenix.sh /etc/bootstrap-phoenix.sh

RUN chown root:root /etc/bootstrap-phoenix.sh
RUN chmod 700 /etc/bootstrap-phoenix.sh
ENTRYPOINT ["/etc/bootstrap-phoenix.sh"]
CMD ["-d"]

EXPOSE 8765 2181
