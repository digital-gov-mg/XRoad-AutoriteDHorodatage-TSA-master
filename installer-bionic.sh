#!/usr/bin/env bash
    timedatectl set-timezone Africa/Nairobi;
    hostnamectl set-hostname signserver;
    sudo cp -rf configurer-jboss/ /opt/
    sudo cp -rf services/ /opt/
    sudo cp  -f  *.properties /opt/
    sudo  cp  -f  *.sh        /opt/
    apt-get update;     
    apt-get -y install  openjdk-8-jre-headless ca-certificates-java;
    apt-get -y install openjdk-8-jdk unzip ntp ant ant-optional postgresql postgresql-client;  
  
    mkdir -p  /etc/jboss; cd /opt/;
    unzip -q /opt/signserver-ce-5.2.0.Final-bin.zip;
    unzip -q /opt/jboss-eap-7.0.0.zip;
    mv /opt/jboss-eap-7.0 /opt/jboss;
    mv /opt/signserver-ce-5.2.0.Final /opt/signserver;

    cp /opt/*.properties /opt/signserver/conf/;
    mv /opt/services /opt/signserver/;

    mkdir /opt/jboss/standalone/configuration/keystore;
    mkdir /opt/signserver/certificats;
    cd /opt/signserver/certificats/;
    cp /opt/creer-certificats.sh .;   
    chmod +x creer-certificats.sh; ./creer-certificats.sh;
   
    cp /opt/configurer-jboss/jboss.conf /etc/jboss/;
    cp /opt/configurer-jboss/jboss.service /etc/systemd/system/;
    touch /etc/profile.d/signer.sh;
    echo "export APPSRV_HOME=/opt/jboss" >> /etc/profile.d/signer.sh;
    echo "export SIGNSERVER_NODEID=node1" >> /etc/profile.d/signer.sh;

    groupadd -r jboss;
    useradd -r -g jboss -d /opt/jboss -s /sbin/nologin jboss;
    useradd -r -g jboss -d /opt/signserver -s /bin/bash signer;
    echo 'signer:signer' | sudo chpasswd;
    chown -R jboss:jboss /opt/jboss;
    chown -R signer:jboss /opt/signserver;
    chmod 775 -R  /opt/jboss /opt/signserver;
    systemctl start jboss.service;
    systemctl enable jboss.service;

sudo -u postgres psql -U postgres <<OMG
 CREATE USER signserver WITH PASSWORD 'signserver';
 CREATE DATABASE signserver WITH OWNER signserver ENCODING 'UTF8' ;
OMG
