#!/bin/bash


#rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# HADOOP #####################################################################################################################
# kerberos client
sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" /etc/krb5.conf
sed -i "s/example.com/${DOMAIN_REALM}/g" /etc/krb5.conf

# update config files
sed -i "s/9000/8020/g" $HADOOP_PREFIX/etc/hadoop/core-site.xml
sed -i "s/HOSTNAME/${FQDN}/g" $HADOOP_PREFIX/etc/hadoop/core-site.xml
sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $HADOOP_PREFIX/etc/hadoop/core-site.xml
sed -i "s#/etc/security/keytabs#${KEYTAB_DIR}#g" $HADOOP_PREFIX/etc/hadoop/core-site.xml

sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
sed -i "s/HOSTNAME/${FQDN}/g" $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
sed -i "s#/etc/security/keytabs#${KEYTAB_DIR}#g" $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
sed -i "s/HOSTNAME/${FQDN}/g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
sed -i "s#/etc/security/keytabs#${KEYTAB_DIR}#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
sed -i "s/HOSTNAME/${FQDN}/g" $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
sed -i "s#/etc/security/keytabs#${KEYTAB_DIR}#g" $HADOOP_PREFIX/etc/hadoop/mapred-site.xml

sed -i "s#/usr/local/hadoop/bin/container-executor#${NM_CONTAINER_EXECUTOR_PATH}#g" $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

# create namenode kerberos principal and keytab
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -pw ${KERBEROS_ROOT_USER_PASSWORD} root@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey nn/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey dn/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey HTTP/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey jhs/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey yarn/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey rm/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey nm/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey user@${KRB_REALM}"

kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k nn.service.keytab nn/$(hostname -f)"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k dn.service.keytab dn/$(hostname -f)"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k spnego.service.keytab HTTP/$(hostname -f)"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k jhs.service.keytab jhs/$(hostname -f)"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k yarn.service.keytab yarn/$(hostname -f)"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k rm.service.keytab rm/$(hostname -f)"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k nm.service.keytab nm/$(hostname -f)"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k user.headless.keytab user"

mkdir -p ${KEYTAB_DIR}
mv nn.service.keytab ${KEYTAB_DIR}
mv dn.service.keytab ${KEYTAB_DIR}
mv spnego.service.keytab ${KEYTAB_DIR}
mv jhs.service.keytab ${KEYTAB_DIR}
mv yarn.service.keytab ${KEYTAB_DIR}
mv rm.service.keytab ${KEYTAB_DIR}
mv nm.service.keytab ${KEYTAB_DIR}
mv user.headless.keytab ${KEYTAB_DIR}
chmod 400 ${KEYTAB_DIR}/nn.service.keytab
chmod 400 ${KEYTAB_DIR}/dn.service.keytab
chmod 400 ${KEYTAB_DIR}/spnego.service.keytab
chmod 400 ${KEYTAB_DIR}/jhs.service.keytab
chmod 400 ${KEYTAB_DIR}/yarn.service.keytab
chmod 400 ${KEYTAB_DIR}/rm.service.keytab
chmod 400 ${KEYTAB_DIR}/nm.service.keytab
chmod 400 ${KEYTAB_DIR}/user.headless.keytab
#########################################################################################################################################

# hbase kerberos
sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $HBASE_HOME/conf/hbase-site.xml
sed -i "s/HOSTNAME/${FQDN}/g" $HBASE_HOME/conf/hbase-site.xml
sed -i "s#/etc/security/keytabs/hbase.keytab#${HBASE_KEYTAB_FILE}#g" $HBASE_HOME/conf/hbase-site.xml
sed -i "s/fully.qualified.domain.name/$(hostname -f)/g" $HBASE_HOME/conf/hbase-server.jaas
sed -i "s/fully.qualified.domain.name/$(hostname -f)/g" $HBASE_HOME/conf/hbase-client.jaas
sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $HBASE_HOME/conf/hbase-server.jaas
sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $HBASE_HOME/conf/hbase-client.jaas
sed -i "s#/etc/security/keytabs/hbase.keytab#${HBASE_KEYTAB_FILE}#g" $ZOO_HOME/conf/hbase-server.jaas
sed -i "s#/etc/security/keytabs/hbase.keytab#${HBASE_KEYTAB_FILE}#g" $ZOO_HOME/conf/hbase-client.jaas
sed -i "s#/etc/hbase/conf/hbase-env.sh#${HBASE_HOME}/conf/hbase-env.sh#g" $HBASE_HOME/conf/hbase-env.sh

# zookeeper kerberos
sed -i "s/fully.qualified.domain.name/$(hostname -f)/g" $ZOO_HOME/conf/zookeeper-server.jaas
sed -i "s/fully.qualified.domain.name/$(hostname -f)/g" $ZOO_HOME/conf/zookeeper-client.jaas
sed -i "s/EXAMPLE.COM/${KRB_REALM}/g" $ZOO_HOME/conf/zookeeper-client.jaas
sed -i "s#/etc/security/keytabs/zookeeper.keytab#${ZOOKEEPER_KEYTAB_FILE}#g" $ZOO_HOME/conf/zookeeper-server.jaas
sed -i "s#/etc/security/keytabs/zookeeper.keytab#${ZOOKEEPER_KEYTAB_FILE}#g" $ZOO_HOME/conf/zookeeper-client.jaas

# create hbase kerberos principal and keytab
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey hbase/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k hbase.keytab hbase/$(hostname -f)"
mkdir -p $KEYTAB_DIR
mv hbase.keytab $KEYTAB_DIR
chmod 400 $KEYTAB_DIR/hbase.keytab

# create zookeeper kerberos principal and keytab
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "addprinc -randkey zookeeper/$(hostname -f)@${KRB_REALM}"
kadmin -p ${KERBEROS_ADMIN} -w ${KERBEROS_ADMIN_PASSWORD} -q "xst -k zookeeper.keytab zookeeper/$(hostname -f)"
mkdir -p $KEYTAB_DIR
mv zookeeper.keytab $KEYTAB_DIR
chmod 400 $KEYTAB_DIR/zookeeper.keytab

$HADOOP_PREFIX/bin/hdfs namenode -format
service sshd start
$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver
$ZOO_HOME/bin/zkServer.sh start

printf "${KERBEROS_ROOT_USER_PASSWORD}" | kinit root@${KRB_REALM}
adduser hbase
groupadd hadoop
usermod -a -G hadoop hbase
hdfs dfs -mkdir /hbase
hdfs dfs -chown -R hbase:hadoop /hbase
kdestroy
$HBASE_HOME/bin/hbase-daemon.sh --config "/usr/local/hbase/conf" start master
$HBASE_HOME/bin/hbase-daemon.sh --config "/usr/local/hbase/conf" start regionserver
if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi

if [[ $1 == "-sqlline" ]]; then
  /usr/local/phoenix/hadoop2/bin/sqlline.py localhost
fi
