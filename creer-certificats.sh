
###
#Création des certificats que JBoss utilisera pour servir HTTPS
# REMARQUE: si vous modifiez les mots de passe, assurez-vous de changer également  scripts/conf-jboss04.cli 
###

rm -rf client.crt  client.jks  tsaclient.p12  keystore.jks  truststore.jks;

#Serveur Key
keytool -genkey -v -validity 730 -alias timestamp -keyalg RSA \
-sigalg SHA256withRSA -keysize 2048 -keystore keystore.jks \
-storepass egovmgkidona  -keypass egovmgkidona \
-dname 'CN=serveurTSA, OU=EGM, O=Gouvernement Malagasy, C=MG,email=service.tsa@tsa.gov.mg' \
-ext SAN=dns:tsa.minx.gov.mg;

# Cliente key
keytool -genkey -keystore client.jks -storepass egovmgkidona -validity 730 \
-keyalg RSA -sigalg SHA256withRSA -keysize 2048 -storetype pkcs12 \
-dname 'CN=clientTSA, OU=EGM, O=Gouvernement Malagasy, C=MG,email=client.tsa@tsa.gov.mg';

#Exporter la clé publique du client
keytool -exportcert -keystore client.jks  -storetype pkcs12 -storepass egovmgkidona \
-keypass egovmgkidona -file client.crt;

#Ajouter la clé publique du client au magasin de confiance (Truststore)
keytool -import -file client.crt -trustcacerts -noprompt -storepass egovmgkidona -keystore truststore.jks;

#Créer une balle d'identité client P12
keytool -importkeystore -srckeystore client.jks -destkeystore client-tsa.p12 \
-srcstorepass egovmgkidona  -srcstoretype PKCS12 -deststoretype PKCS12 -deststorepass egovmgkidona;

cp *jks /opt/jboss/standalone/configuration/keystore;
